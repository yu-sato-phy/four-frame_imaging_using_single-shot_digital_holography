pkg load image;
pkg load signal;

% clf
close all
clear

conf = get_config();

addpath('functions');

files = glob(fullfile(conf.image_dir, sprintf('/*.tiff')));
target_file = files{end};  % 最後のファイルのみ処理

[~, name, ~] = fileparts(target_file);
outdir = conf.outdir_prepare;
if ~exist(outdir, 'dir')
  mkdir(outdir)
endif

state_file = 'state.mat'; % 状態を保存するファイル名
if (exist(state_file, 'file'))
  % 保存ファイルがあれば読み込む
  load(state_file);
  if (strcmp(base_filename, name))
    if(conf.is_new_file_when_same == true)
    run_count = run_count + 1; % 実行回数を1増やす
    endif
  else
    run_count = 1;
  endif
else
  % なければ初回実行として変数を初期化
  fid = fopen(state_file, 'w');
  fclose(fid);
  base_filename = name; % ベースとなるファイル名
  run_count = 0;
  save(state_file, 'base_filename', 'run_count');
  run_count = 1;
endif
base_filename = name; % ベースとなるファイル名

peak_coords = get_peaks(target_file, run_count, conf);

% 位相の構造体（labelは画像の種類（例: 45_01, 45_02, r_01等））を得る．
[amp_struct, pha_struct] = process_image(target_file, peak_coords, conf);

fields = fieldnames(pha_struct);
for k = 1:length(fields)
  label = fields{k};  % 例: '45_01'

  % label を angle_str と point に分解
  parts = strsplit(label, '_');
  angle_str = parts{1};        % 例: '45'，'r'
  point = parts{2};            % 例: '01'

  % ファイル名構築
  if (run_count == 1)
    filename = sprintf('%s_%d_%s_%s.png', name, k, angle_str, point);
  else
    if(run_count == 2)
    % カッコなしファイルに (1) をつける．（ソートが気持ち悪くなる為）
      filename_old = fullfile(outdir, sprintf('%s_%d_%s_%s.png', name, k, angle_str, point));
      filename_new = fullfile(outdir, sprintf('%s (1)_%d_%s_%s.png', name, k, angle_str, point));
      if(exist(filename_old, 'file'))
        movefile(filename_old, filename_new);
        endif
    endif
    filename = sprintf('%s (%d)_%d_%s_%s.png', name, run_count, k, angle_str, point);
  endif
  outpath = fullfile(outdir, filename);

  % phase 画像を書き出し
  if conf.save_pha_in_prepare
    imwrite(normalize_image(pha_struct.(label)), outpath);
  elseif conf.save_amp_in_prepare
    imwrite(normalize_image(amp_struct.(label)), outpath);
  elseif conf.save_ins_in_prepare
    imwrite(normalize_image((amp_struct.(label)).^2), outpath);
  end

  % ノイズ計測
  if conf.phase_noise_checker
    if k == 1
      fprintf('-- RMS Phase Noise [rad]\n')
    endif
    unwrapped_phase = p_unwrap(pha_struct.(label), conf);
    phase_noise = noise_checker(unwrapped_phase);
    fprintf('%s: %f\n', label, phase_noise)
  endif

end

fclose('all');    % 念のため開いてるフォルダを閉じる．
% 正常に終わり次第run_countをセーブ
save(state_file, 'base_filename', 'run_count');

