import re
import pickle
import pandas as pd
import numpy as np
import matplotlib
import traceback
import matplotlib.pyplot as plt
from matplotlib import cm, font_manager, gridspec
from tqdm.auto import tqdm
import seaborn as sns
from pathlib import Path
import utils
import ghostipy as gsp
from statistics import mode
from scipy.optimize import curve_fit
from scipy.stats import linregress, ttest_ind, sem
from scipy.io import savemat, loadmat
from scipy.signal import find_peaks, hilbert, spectrogram, filtfilt


matplotlib.rcParams['pdf.fonttype'] = 42
# set paper font
font_dirs = ['/usr/share/fonts/truetype/myriad-pro-regular']
font_files = font_manager.findSystemFonts(fontpaths=font_dirs)
for font_file in font_files:
    font_manager.fontManager.addfont(font_file)
plt.rcParams['font.family'] = 'Myriad Pro'
animal_colors = {
    'SA03':	(0, 0.447, 0.741),
    'SA04': (0.850, 0.325, 0.098),
    'SA05': (0.929, 0.694, 0.125),
    'SA06': (0.494, 0.184, 0.556),
    'SA07': (0.466, 0.674, 0.188),
    'SA09': (0.301, 0.745, 0.933),
    'SA10': (0.635, 0.078, 0.184),
    'SA11': (0.741, 0.447, 0),
    'SA15': (0.098, 0.325, 0.850)
}
ALPHA = 0.6
cycles_compare = ['SA07,sleepNight22', 'SA07,sleepNight24', 'SA07,sleepNight29']
example_rec = 'SA07,sleepNight25'


class ShWPlotter:
    def __init__(self, output_folder='.', shw_duration=1.2, use_cache=True):
        self.shw_duration = shw_duration
        self.cycle_t = None  # time vector for cycles analyses, needed for plots
        self.cycles_rates = {}
        self.all_nights = {}
        self.temps = {}
        self.sw_dfs = {}
        self.avg_shw_shapes = {}
        self.phase_db, self.t_phase = None, None
        self.gdf = pd.DataFrame()
        self.v_example, self.t_example = None, None
        self.summary_df = pd.DataFrame()
        self.bad_recordings = []
        self.tmpl = get_match_filter()
        assert Path(output_folder).exists() and Path(output_folder).is_dir()
        self.output_folder = Path(output_folder) / 'cache'
        self.output_folder.mkdir(exist_ok=True)
        if use_cache:
            self.load_cache()
        self.colormap = cm.get_cmap('coolwarm', len(set(self.temps.values())))
        self.colors = {int(k): self.colormap(i) for i, k in enumerate(sorted(set(self.temps.values())))}
        self.example_detector = None

    def analysis_summary(self):
        for i, (name, temp) in enumerate(self.temps.items()):
            rate = self.cycles_rates[name]
            sw_df = self.sw_dfs[name]
            all_night = self.all_nights[name]
            q = all_night.datetime.dt.strftime('%H:%M:%S')
            all_night = all_night[(q >= '19:00') | (q <= '07:00')]
            self.summary_df.loc[i, 'animal_id'] = name.split(',')[0]
            self.summary_df.loc[i, 'name'] = name
            self.summary_df.loc[i, 'temp'] = temp
            # auto-correlation
            self.summary_df.loc[i, ['t_cyc', 'power', 'power_norm', 'r', 'lag']] = utils.autocorr(rate, self.cycle_t)
            # ShW widths
            self.summary_df.loc[i, 'width'] = sw_df.query('power>0.4').width.mean()
            self.summary_df.loc[i, 'depth'] = sw_df.query('power>0.4').depth.mean()
            # total ShW
            self.summary_df.loc[i, 'total_sw'] = len(sw_df)
            # ShW/cycle
            self.summary_df.loc[i, 'sw_per_cyc'] = sw_df.groupby('signal').start.count().mean()
            # max cycle rate value
            self.summary_df.loc[i, 'max_cyc_rate'] = rate[:len(rate) // 2].max()
            self.summary_df.loc[i, 'p2v'] = rate[:len(rate) // 2].max() - rate[len(rate) // 2:].min()
            self.summary_df.loc[i, 'all_night_avg'] = all_night.rate.mean()
        self.bad_recordings = [tuple(x) for x in self.summary_df.query('power<0.3')[['animal_id',
                                                                                     'name']].to_records(index=False)]

    def temperature_figure(self):
        """Plot all figures about ShW vs. temperature"""
        fig, axes = plt.subplots(2, 5, dpi=130, figsize=(10, 4), gridspec_kw={"width_ratios": [1, 12, 12, 12, 12]})
        self.plot_sw_around_cycle_transition(axes[0, 1])
        self.plot_rate_all_night(axes[0, 2])
        self.plot_sw_shapes(axes[1, 1])

        for ax in axes[:, -1]:  # remove the underlying axes
            ax.remove()
        gs = axes[0, 3].get_gridspec()
        ax_big = fig.add_subplot(gs[:, -1])
        h, l = self.plot_sw_cycle_oscil_freq(ax_big)

        l, h = zip(*sorted(zip(l, h), key=lambda t: t[0]))
        for lh in h:
            lh.set_alpha(ALPHA)
        axes[1, 0].legend(h, l, borderaxespad=0, fontsize=8, bbox_to_anchor=(1, 1))
        axes[0, 0].axis("off")
        axes[1, 0].axis("off")

        self.plot_sw_widths(axes[1, 2])
        self.plot_sw_depths(axes[1, 3])
        self.plot_sw_avg_rate(axes[0, 3])
        fig.tight_layout()

        min_temp, max_temp = int(min(self.temps.values())), int(max(self.temps.values()))
        sm = plt.cm.ScalarMappable(cmap=self.colormap, norm=plt.Normalize(vmin=min_temp, vmax=max_temp))
        cbar_ax = fig.add_axes([0.05, 0.78, 0.01, 0.17])
        # fig.colorbar(sm, cax=cbar_ax, ticks=[min_temp, max_temp])
        fig.savefig('plots/temps.pdf')

    def supplementary_figure(self):
        fig = plt.figure(tight_layout=True, figsize=(10, 5), dpi=130)
        cols = 5
        gs = gridspec.GridSpec(3, cols, height_ratios=[1, 3, 3], width_ratios=[1, 1, 1, 1, 6])
        ax = fig.add_subplot(gs[0, 1])
        c = 'darkblue'
        ax.plot(self.tmpl, c, linewidth=2)
        ax.arrow(len(self.tmpl), self.tmpl.mean(), len(self.tmpl) / 2, 0, color=c, head_width=20)
        ax.arrow(0, self.tmpl.mean(), -len(self.tmpl) / 2, 0, color=c, head_width=20)
        ax.axis('off')
        self.plot_sharp_waves_detection(fig.add_subplot(gs[1, :cols - 1]), fig.add_subplot(gs[2, :cols - 1]))
        ax = fig.add_subplot(gs[1, cols - 1])
        self.plot_rate_all_night(ax, recs=[cycles_compare[1]], is_legend=True)
        fig.savefig('plots/supplementary.pdf')

    def plot_sharp_waves_detection(self, ax, ax2, thresh=0.2, shw_w=360, fs=300):
        v = utils.smooth_signal(self.v_example.flatten(), poly_order=7)
        ax.plot(self.t_example, self.v_example, 'k')
        ax.axis('off')
        power = -filtfilt(self.tmpl[::-1], 1, v)
        conv = power / power.max()
        peaks_, _ = find_peaks(conv, height=thresh, distance=fs * 0.5, width=fs * 0.1)
        peaks_ = [p for p in peaks_ if p > 0 and v[p] < -20]
        mw = shw_w // 2
        for peak in peaks_:
            ax.axvspan(self.t_example[max([peak-mw, 0])], self.t_example[min([len(self.t_example)-1, peak+mw])],
                       facecolor='g', alpha=0.4)

        ax2.plot(self.t_example, conv, 'k')
        ax2.scatter(self.t_example[peaks_], conv[peaks_], c='g', alpha=0.4)
        ax2.axis('off')
        ax2.axhline(0, c='k')
        ax2.axhline(thresh)

    def phase_figure(self):
        fig, axes = plt.subplots(1, 2, dpi=130, figsize=(6, 3))
        axes[0].plot(self.t_phase.flatten(), self.phase_db.flatten(), label=r'$\delta/\beta$')
        axes[0].legend()
        sns.violinplot(data=self.gdf.drop(columns=['Unnamed: 0']), ax=axes[1])
        axes[1].set_ylabel('In-cycle ShW ratio')
        tt, p_val = ttest_ind(self.gdf.SWS, self.gdf.REM, equal_var=False)
        print(f't={tt:.3f} , P={p_val:.1e}')
        fig.tight_layout()
        fig.savefig('plots/phase.pdf')

    def plot_sw_around_cycle_transition(self, ax=None):
        if ax is None:
            ax = plt.subplot(figsize=(6, 3), dpi=140)
        t_ = self.cycle_t[2:-2] - self.cycle_t[-1] / 2
        for name, temp in self.temps.items():
            if name not in cycles_compare:
                continue
            rate = self.cycles_rates[name]
            ax.plot(t_, rate[2:-2] / 20, color=self.colors[int(temp)])
        ax.axvline(0, color='k', linestyle='--')
        ax.set_xlabel('Time [sec]', fontsize=9)
        ax.set_ylabel('Rate [#ShW/sec]', fontsize=9)

    def plot_rate_all_night(self, ax, recs=(), is_legend=None):
        hour_start, hour_stop = 17, 9
        x = np.arange(0, hour_stop + (24 - hour_start), 0.25)
        if ax is None:
            ax = plt.subplot(figsize=(6, 3), dpi=140)
        averaged = []
        sumf = self.summary_df.copy().set_index('name')
        for name, temp in self.temps.items():
            if sumf.loc[name, 'power'] < 0.4 and (name not in cycles_compare) and (name not in recs):
                continue
            rf = self.all_nights[name].copy().reset_index()[['rate', 'time', 'datetime']]
            rf.time = rf.time / 3600
            # rf.datetime = rf.datetime.dt.strftime('%H:%M')
            dt = rf.datetime.copy().dt
            rf.datetime = dt.hour + (dt.minute / 60)
            rf = rf.loc[(rf.datetime >= hour_start) | (rf.datetime <= hour_stop), :]
            # rf = rf.query(f'datetime >= {hour_start} and datetime <= {hour_stop}')
            dtm = rf.datetime.copy()
            rf.loc[dtm >= hour_start, 'datetime'] = rf.loc[dtm >= hour_start, 'datetime'] - hour_start
            rf.loc[dtm <= hour_stop, 'datetime'] = rf.loc[dtm <= hour_stop, 'datetime'] + (24 - hour_start)
            rate = np.interp(x, rf.datetime.values, rf.rate.values)
            averaged.append(rate)
            if (recs and name not in recs) or (not recs and name not in cycles_compare):
                continue
            sns.lineplot(data=rf, x='datetime', y='rate', color=self.colors[int(temp)], ax=ax,
                         label=is_legend and f'{int(temp)}ºC', zorder=10)

        avf = np.vstack(averaged)
        sns.lineplot(x=x, y=avf.mean(axis=0), color='k', ax=ax, label=is_legend and 'Average')#,
                     # ci=None)
        ax.fill_between(x, avf.mean(axis=0) - sem(avf, axis=0), avf.mean(axis=0) + sem(avf, axis=0), alpha=0.4)
        ax.set_xlabel('Hour', fontsize=9)
        ax.set_ylabel('Rate [#ShW/hour]', fontsize=9)
        ax.set_xticks([19-hour_start, (24-hour_start), 7+(24-hour_start)], ['19:00', '00:00', '07:00'])
        ax.axvspan(19-hour_start, 7+(24-hour_start), facecolor='silver', alpha=0.3)
        if is_legend:
            h, l = ax.get_legend_handles_labels()
            ax.legend(h, l)
        return averaged

    def plot_sw_shapes(self, ax):
        for name, v in self.avg_shw_shapes.items():
            temp = self.temps[name]
            t_ = np.linspace(-self.shw_duration/2, self.shw_duration/2, len(v))
            ax.plot(t_, v, label=f'{temp}', color=self.colors[int(temp)])
        ax.set_xlabel('Time [sec]', fontsize=9)
        ax.set_ylabel('Voltage [mV]', fontsize=9)
        ax.set_xticks([-0.5, 0, 0.5], ['-0.5', '0', '0.5'])

    def plot_sw_cycle_oscil_freq(self, ax, T0=17, p0=(2.2, 1.7)):
        data = self.summary_df.query('power>0.3').copy()
        data['freq'] = 1 / (data.t_cyc / 60)
        xdata = data['temp'].values
        ydata = data['freq'].values
        def q10(T, *P): return P[1] * P[0] ** ((T - T0) / 10)
        popt, pcov = curve_fit(q10, xdata, ydata, p0=p0)
        sns.scatterplot(data=data, x='temp', y='freq', hue='animal_id', ax=ax, palette=animal_colors, alpha=ALPHA,
                        edgecolor='black', s=18)
        ax.plot(xdata, q10(xdata, *popt), 'k-', label=r'$Q_{10}$' + f' = {popt[0]:.2f}')
        h, l = ax.get_legend_handles_labels()
        ax.legend(h[-1:], l[-1:])
        ax.set_xlabel('Temperature [ºC]', fontsize=9)
        ax.set_ylabel('Oscil. freq [1/min]', fontsize=9)
        ax.set_xticks([20, 25, 30, 35])
        return h[:-1], l[:-1]

    def _plot_general_metric(self, ax, col, use_stat=True, label=None):
        label = label or col
        assert col in self.summary_df.columns, f'Column {col} is unknown'
        data = self.summary_df.query('power>0.3 and animal_id not in ["SA10","SA11"]').copy()
        # group normalization
        for animal_id, idx in data.groupby('animal_id').groups.items():
            data.loc[idx, col] = (data.loc[idx, col] - data.loc[idx, col].mean()) / data.loc[idx, col].std()
        sns.scatterplot(data=data, x='temp', y=col, hue='animal_id', ax=ax, palette=animal_colors, alpha=ALPHA,
                        edgecolor='black', s=18)
        if use_stat:
            slope, intercept, r, p_r, se = linregress(data.temp.values, data[col].values)
            c, p_c = utils.corrcoef(np.vstack([data.temp.values, data[col].values]))
            print(f'Statistics for {col} vs. temp: r^2={r ** 2:.3f},p-value={p_r:.0e}, '
                  f'corr={c[0, 1]:.3f},p-value={p_c[0, 1]:.0e}')
            X = data.temp.values.reshape(-1, 1)
            ax.plot(X.squeeze(), X.squeeze() * slope + intercept, 'k')
        ax.legend([], [], frameon=False)
        ax.set_xlabel('Temperature [ºC]', fontsize=9)
        ax.set_ylabel(f'norm. ShW {label}', fontsize=9)
        ax.legend([], [], frameon=False)
        ax.set_xticks([20, 25, 30, 35])

    def plot_sw_depths(self, ax):
        self._plot_general_metric(ax, 'depth')

    def plot_sw_widths(self, ax):
        self._plot_general_metric(ax, 'width')

    def plot_sw_avg_rate(self, ax):
        self._plot_general_metric(ax, 'all_night_avg', use_stat=False, label='mean rate')

    @staticmethod
    def get_rec_temperature(rp):
        temp = rp.excel_table.get('tempMedian')
        if not temp or (isinstance(temp, float) and np.isnan(temp)):
            temp = rp.excel_table.get('Temp')
        return temp

    @property
    def cached_variables(self):
        return ['cycle_t', 'cycles_rates', 'all_nights', 'temps', 'sw_dfs', 'avg_shw_shapes', 't_example',
                'v_example', 'gdf', 'phase_db', 't_phase']

    def load_cache(self):
        assert self.cache_filename.exists(), f'{self.cache_filename} does not exist'
        with self.cache_filename.open('rb') as f:
            d = pickle.load(f)
        for k in self.cached_variables:
            assert k in d.keys(), f'{k} is missing in the cache file from {self.cache_filename}'
            setattr(self, k, d[k])
        self.analysis_summary()

    def save_cache(self):
        d = {k: getattr(self, k) for k in self.cached_variables}
        with self.cache_filename.open('wb') as f:
            pickle.dump(d, f)

    @property
    def cache_filename(self):
        return self.output_folder / 'shw.pkl'


class RipplesPlotter:
    def __init__(self, shw_duration=2.5, shw_threshold=0.2, shw_per_rec=1000,
                 only_sleep=False, exclude=None, min_shws=50, use_cwt_cache=True, cwt_recs=(),
                 animals_order=None, output_folder='.'):
        self.tmpl = get_match_filter()
        self.shw_per_rec = shw_per_rec
        self.only_sleep = only_sleep
        self.exclude = exclude
        self.min_shws = min_shws
        self.use_cwt_cache = use_cwt_cache
        self.cwt_recs = cwt_recs
        self.shw_duration = shw_duration
        self.shw_threshold = shw_threshold
        self.animals_order = animals_order
        self.output_folder = Path(output_folder) / 'cache'

    def ripples_figure(self):
        sns.set_context('paper', font_scale=1.4)
        with (self.output_folder / 'ripples.pkl').open('rb') as f:
            d = pickle.load(f)
        # {'all_animals_data': all_animals_data, 'spec': spec, 't_spec': t_spec, 'f_spec': f_spec,
        #  'B': B, 't_flt': t_flt, 'example_v': example_v, 'example_t': example_t}

        fig = plt.figure(tight_layout=True, figsize=(16, 3*4))
        gs = gridspec.GridSpec(3, 3)
        self.plot_shw_example(d['example_v'], d['example_t'], fig.add_subplot(gs[0, 0]))
        self.plot_cwt(d['spec'], d['t_spec'], d['f_spec'], fig.add_subplot(gs[1, 0]), is_log_norm=False)
        self.plot_filtered_trace(d['B'], d['t_flt'], fig.add_subplot(gs[2, 0]))

        self.plot_all_animals_band(fig.add_subplot(gs[1:, 1]), d['all_animals_data'])
        self.plot_all_animals_cwt(fig.add_subplot(gs[0, 1]), d['all_animals_data'])

        fig.tight_layout()
        fig.savefig('plots/ripples.pdf')

    def get_shw_indices(self, rp, swf):
        shw_df = swf.shw_df.copy()
        shw_df = shw_df.sort_values('power', ascending=False)[:self.shw_per_rec].reset_index(drop=True)
        expected_diff = None
        idx = []
        for i, row in shw_df.iterrows():
            i_start, i_stop = int(swf.t[int(row.start)] * rp.fs), int(swf.t[int(row.end)] * rp.fs)
            diff = i_stop - i_start
            if i == 0:
                expected_diff = diff
            elif diff < expected_diff:
                i_stop += expected_diff - diff
            elif diff > expected_diff:
                i_stop -= diff - expected_diff
            idx.append((i_start, i_stop))
        return np.array(idx)

    def run_spectrogram(self, idx, window_sec=0.1, maxy=10000):
        fs = self.rp.fs
        nfft = int(window_sec * fs)
        noverlap = int(nfft * 0.95)  # overlap set to be half of a segment
        nfft_padded = utils.next_power_of_2(nfft)  # pad segment with zeros for making nfft of power of 2 (better performance)
        S = None
        count = 0
        for i_start, i_stop in tqdm(idx, total=idx.shape[0]):
            v_, t_ = self.rp.read(i_start=i_start, i_stop=i_stop)
            # vmin = 20 * np.log10(np.max(v_)) - 40  # hide anything below -90 dBc
            f_sp, t_sp, Sxx = spectrogram(v_, fs, nperseg=nfft, noverlap=noverlap, nfft=nfft_padded, window='hann')
            # Sxx = np.abs(Sxx) ** 2 / fs
            if S is None:
                S = Sxx
            else:
                S += Sxx
            count += 1
        f_idx = (f_sp >= 20) & (f_sp <= 700)
        f_sp = f_sp[f_idx]
        S = S[f_idx, :]
        S = S / count
        return S, t_sp, f_sp

    def run_cwt(self, swf, idx, use_cache=False):
        cache_path = swf.reader.cache_dir_path / f'cwt_shw_{len(idx)}.pkl'
        if use_cache and cache_path.exists():
            print(f'{swf.reader}: loading CWT cache')
            with cache_path.open('rb') as f:
                d = pickle.load(f)
                S, t_sp, f_sp = d['S'], d['t_sp'], d['f_sp']
        else:
            S = None
            count = 0
            shw_length = int(swf.shw_duration_sec * swf.fs)
            for i in tqdm(idx, desc=f'run_cwt {swf.reader}'):
                v_, t_ = swf.shw_records[str(i)]
                if self.check_max_pos(v_) or len(t_) < shw_length:
                    continue
                elif len(t_) > shw_length:
                    v_, t_ = v_[:shw_length], t_[:shw_length]
                v_ = utils.notch_filter(v_, swf.fs)
                Sxx, _, f_sp, t_sp, _ = gsp.cwt(v_, fs=swf.fs, timestamps=t_, freq_limits=[20, 500], voices_per_octave=32)
                Sxx = np.abs(Sxx) ** 2 / swf.fs
                if S is None:
                    S = Sxx
                else:
                    S += Sxx
                count += 1
            S = S / count
            cache_path.parent.mkdir(exist_ok=True, parents=True)
            with cache_path.open('wb') as f:
                pickle.dump({'S': S, 't_sp': t_sp, 'f_sp': f_sp}, f)

        return S, t_sp, f_sp

    def get_filtered_shw(self, swf, idx, freq_limits=(60, 199), order=5):
        B = []
        for i in idx.copy():
            v_, t_ = swf.shw_records[str(i)]
            if self.check_max_pos(v_):
                idx.remove(i)
                continue
            band_v = utils.butter_bandpass_filter(v_, freq_limits[0], freq_limits[1], fs=swf.reader.fs, order=order)
            B.append(band_v)
        return B, t_ - t_[0], idx

    def run_hilbert(self, B):
        modeB = mode([len(b) for b in B])
        hilb = np.zeros((modeB,))
        count = 0
        for b in B:
            if len(b) != modeB:
                continue
            analytic_signal = hilbert(b)
            b = np.abs(analytic_signal)
            hilb += b
            count += 1
        return hilb / count

    def run_filtered_and_avg(self, swf, shw_indices, padding):
        B, t_flt, shw_indices = self.get_filtered_shw(swf, shw_indices)
        analytic = self.run_hilbert(B)
        y_flt = analytic[padding:-padding]
        y_flt = (y_flt - y_flt.mean()) / y_flt.std()
        t_avg, y_avg = swf.get_avg_shw(is_plot=False, shw_indices=shw_indices)
        y_avg = (y_avg - y_avg.mean()) / y_avg.std()
        return t_flt, y_flt, t_avg, y_avg, shw_indices

    @staticmethod
    def plot_filtered_trace(filtered_signal, t, ax, padding=None):
        if padding:
            t, filtered_signal = t[padding:-padding], filtered_signal[padding:-padding]
        ax.plot(t, filtered_signal, c='k')
        # plt.title('Band=150-350Hz, order=5, ShW are centered around t=0.35s')
        ax.set_xlabel('Time [sec]')
        ax.set_ylabel('Band-passed filtered')
        ax.grid(False)

    @staticmethod
    def plot_cwt(S, t_sp, f_sp, ax, is_log_norm=False, vmin=None):
        ax.grid(False)
        # S = S.copy()
        # S = S/S.mean(axis=0)[None,:]
        norm = matplotlib.colors.LogNorm() if is_log_norm else None
        if vmin:
            S = 10*np.log10(S/S.max())
        ax.pcolormesh(t_sp - t_sp[0], f_sp, S, cmap='jet', vmin=vmin, norm=norm)
        ax.set_xlabel('Time [sec]')
        ax.set_ylabel('Frequency [Hz]')

    def plot_shw_example(self, v, t, ax):
        ax.plot(t.flatten(), v.flatten(), c='k')
        ax.set_xlabel('Time [sec]')
        ax.set_ylabel('Voltage [mV]')
        ax.grid(False)

    def plot_all_animals_band(self, ax, animals_data, padding=120):
        prev_max = 0
        if self.animals_order:
            animals_data = {k: v for k, v in sorted(animals_data.items(), key=lambda x: self.animals_order.index(x[0]))}
        for animal_id, d in animals_data.items():
            is_label_set = False
            animal_max = 0
            for t_flt, y_flt, t_avg, y_avg, rec_id in zip(d['t_flt'], d['y_flt'], d['t_avg'], d['y_avg'], d['rec_id']):
                y_flt = y_flt + (prev_max + 1 - y_flt.min())
                y_avg = y_avg + (prev_max + 1 - y_avg.max())
                label = animal_id if not is_label_set else None
                ax.plot(t_flt[padding:-padding], y_flt, c=animal_colors[animal_id], label=label)
                if not is_label_set:
                    is_label_set = True
                ax.plot(t_avg[padding:-padding], y_avg[padding:-padding], c=animal_colors[animal_id])
                # ax.text(t_flt[-1], y_flt.max(), rec_id, c=animal_colors[animal_id])
                if y_flt.max() > animal_max:
                    animal_max = y_flt.max()
            prev_max = animal_max + 2

        ax.set_xlabel('Time [sec]')
        ax.set_ylabel('Band passed filtered signals + Average ShW')
        ax.legend(bbox_to_anchor=(-0.2, 0.9))
        ax.grid(False)

    def plot_all_animals_cwt(self, ax, animals_data):
        S, t_sp, f_sp, count = None, None, None, 0
        for animal_id, d in animals_data.items():
            for S_, t_sp_, f_sp_ in zip(d['S'], d['t_sp'], d['f_sp']):
                if S_ is None:
                    continue
                if S is None:
                    S, t_sp, f_sp = S_.copy(), t_sp_.copy(), f_sp_.copy()
                else:
                    S += S_
                count += 1
        S = S / count
        self.plot_cwt(S, t_sp, f_sp, ax) # , vmin=-10

    def get_avg_shw(self, rp, idx):
        AVG = None

        for i_start, i_stop in idx:
            v_, t_ = rp.read(i_start=i_start, i_stop=i_stop)
            if AVG is None:
                AVG = v_
            else:
                AVG += v_

        AVG = AVG / len(idx)
        return AVG

    def check_max_pos(self, v_):
        return (v_ > 1000).sum() > 10


def get_match_filter():
    with open('cache/template_filter.np', 'rb') as f:
        tmpl = np.load(f)
    return tmpl


if __name__ == "__main__":
    sp = ShWPlotter()
    sp.temperature_figure()
    sp.phase_figure()
    sp.supplementary_figure()

    rp = RipplesPlotter()
    rp.ripples_figure()

