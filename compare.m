pkg load image;
pkg load signal;

% clf
close all
clear
clear global

addpath('functions');

conf = get_config();

% 1. 準備
% 1.1 カラーバーの設定
N = 256;
cmap = viridis(N);  % colormap (N x 3 のRGB配列)
img_colorbar = get_colorbar_image(conf, cmap);   % カラーバーの作製

% 1.2 ファイルの読み込み
files = glob(fullfile(conf.image_dir, sprintf('/*.tiff')));

% 1.3 変数の初期化
amp_base = struct();
pha_base = struct();
unwrapped_pha_base = struct();

num_one_cycle = conf.num_bases + conf.num_compares;
max_cycles = floor(length(files) / num_one_cycle);
if conf.compare_cycles == 0
  conf.compare_cycles = max_cycles;
end

num_cycles = min(conf.compare_cycles, max_cycles);

% 1123考察
% fresnel_distances = [0.00: 0.02: 0.34];
% fresnel_distances = [0.18: -0.02: -0.14];
% num_fresnel_d = max(size(fresnel_distances));

if size(conf.fresnel_distances) != [0, 0]
  num_cycles = length(conf.fresnel_distances);
end

for compare_index = [1: num_cycles]
  compare_index
  index_start_file = (compare_index - 1) * num_one_cycle + 1;

  % 複数フレネル変換の場合の設定の実装
  if size(conf.fresnel_distances) != [0, 0]
    conf.fresnel_d = conf.fresnel_distances(compare_index);
    conf.fresnel_d
    conf.add_endname_to_file = sprintf('_f%03d', 100 + 100*conf.fresnel_d);
    index_start_file = 1;
  end

  % 2. 周波数シフト量の計算
  peak_coords = get_peaks(files{index_start_file}, 0, conf);
  % peak_coords = get_peaks(files{1}, 0, conf);

  fprintf('\rprogress: files %d / %d base images | ', index_start_file - 1, numel(files));

  % 3. ベース画像の生成
  % 3.1 1つ目の画像に対してのみ実行 (変数領域の定義)
  [amp_base, pha_base] = process_image(files{index_start_file}, peak_coords, conf);
  [~, name_base, ~] = fileparts(files{index_start_file});
  fields = fieldnames(amp_base);
  %{
  for k = 1:length(fields)
    label = fields{k};
    % idx = k * 2 - 1;
    unwrapped_pha_base_sum.(label) = p_unwrap(pha_base.(label), conf);
    amp_base_sum.(label) = amp_base.(label);
  end
  %}

  [amp_base_first, pha_base_first] = process_image(files{index_start_file}, peak_coords, conf);
  [~, name_base, ~] = fileparts(files{index_start_file});
  fields = fieldnames(amp_base_first);
  % 1つ目のベース画像のみstructに収納
  for k = 1:length(fields)
    label = fields{k};
    unwrapped_pha_base_sum.(label) = p_unwrap(pha_base_first.(label), conf);
    amp_base_sum.(label) = amp_base.(label);
  end
  fprintf('\rprogress: files 1 / %d base images | ', numel(files));

  % 3.2 他のベース画像の足し合わせ
  for base_id = index_start_file + 1: index_start_file + conf.num_bases - 1
    % 各ファイルを処理
    fprintf('\r\x1b[Kprogress: files %d / %d base images | processing phases...', base_id-1, numel(files));
    [amp_current, pha_current] = process_image(files{base_id}, peak_coords, conf);
    fprintf('\r\x1b[Kprogress: files %d / %d base images | umwrapping phases...', base_id-1, numel(files));
    % structの各フィールドに対して処理を実行
    for k = 1:length(fields)
      label = fields{k};
      % unwrapして、合計に加える
      unwrapped_pha_base_sum.(label) = unwrapped_pha_base_sum.(label) + p_unwrap(pha_current.(label), conf);
      amp_base_sum.(label) = amp_base_sum.(label) + amp_current.(label);
    end
    fprintf('\r\x1b[Kprogress: files %d / %d', base_id, numel(files));
  end

  % 3.3 ここで平均化されたpha_baseができる．
  for k = 1:length(fields)
      label = fields{k};
      % unwrapして、合計に加える
      unwrapped_pha_base.(label) = unwrapped_pha_base_sum.(label) / conf.num_bases;
      amp_base.(label) = amp_base_sum.(label) / conf.num_bases;
    end

  % fprintf('\r\x1b[Kprogress: files %d / %d phase diff images | make directory...', conf.num_bases, numel(files));

  % 4 出力
  % 4.1 出力ディレクトリの生成
  outdir = 'output';
  if ~exist(outdir, 'dir')
    mkdir('output');
    % mkdir(fullfile(outdir, 'row'));
  endif

  % fprintf('\r\x1b[Kprogress: files %d / %d phase diff images | make colorbar...', conf.num_bases, numel(files));

  % 4.2 カラーバーの保存
  filename = sprintf('999_colorbar.png');
  filepath = fullfile(outdir, filename);
  imwrite(img_colorbar, filepath);

  % 4.3 ベース画像以外の生成
  for kk = index_start_file + conf.num_bases: index_start_file + conf.num_bases - 1 + conf.num_compares
    [~, name, ~] = fileparts(files{kk});
    % 全体figの作製
    if conf.is_save_visualize
    h = figure("visible", "off");
    endif

    if(conf.is_save_original)
      imwrite(imread(files{kk}), fullfile(outdir, sprintf('%02d_01_%s_original.png', kk, label)));
    end
    fprintf('\r\x1b[Kprogress: files %d / %d phase diff images | processing phases...', kk - 1, numel(files));
    % 4.4 心臓部 (位相画像の生成)
    [amp_struct, pha_struct] = process_image(files{kk}, peak_coords, conf);

    for k = 1:length(fields)
      % 各光線ごとのループ
      label = fields{k};
      fprintf('\r\x1b[Kprogress: files %d / %d phase diff images | %s | unwrapping phases...', kk - 1, numel(files), label);
      % idx = k * 2 - 1;
      % 4.5 アンラップ
      unwrapped_pha = p_unwrap(pha_struct.(label), conf);

      % amp, phas減算処理
      pre_amp_diff = amp_struct.(label) - amp_base.(label);
      pre_ins_diff = (amp_struct.(label)).^2 - (amp_base.(label)).^2;
      pre_ins_rate = (amp_struct.(label)).^2 ./ (amp_base.(label)).^2;
      % 正規化してゲインを掛ける
      amp_diff = (pre_amp_diff - mean(mean(pre_amp_diff))) * conf.gain_amp_diff + 0.5;
      ins_diff = (pre_ins_diff - mean(mean(pre_ins_diff))) * conf.gain_ins_diff + 0.5;
      trans_rate = pre_ins_rate / mean(mean(pre_ins_rate));                      % 透過率
      absorbance = -1 * log10(trans_rate);

      % pha減算処理
      row_pha_diff = unwrapped_pha - unwrapped_pha_base.(label);  % [-2pi, 2pi]

  ##    if(k == 3)
  ##      save data.mat row_pha_diff;
  ##    end

      % 中央値を掛ける
      p_median = conf.power_of_median_for_out_Im;
      if(p_median > 0)
        medianned_pha_diff = imsmooth(row_pha_diff, "Median" , [p_median, p_median]);
        amp_diff = imsmooth(amp_diff, "Median" , [p_median, p_median]);
        pha_diff = extract_phase_diff_gray(medianned_pha_diff, conf);
      else
        pha_diff = extract_phase_diff_gray(row_pha_diff, conf);
      end

      idx_map = round(pha_diff * (N - 1)) + 1;
      pha_diff_rgb = ind2rgb(round(pha_diff), cmap);  % RGB画像に変換

      % ==== プラズマ検知処理 =======================================================
      % row_pha_diffからプラズマを検出
      if conf.is_save_auto_detection
        detection_median_p_w = 5;
        detection_median_p_h = 5;
        detection_pha_diff = imsmooth(row_pha_diff, "Median" , [detection_median_p_w, detection_median_p_h]);

        [~, min_line] = min(detection_pha_diff(1: floor(size(row_pha_diff, 2)*0.8), :));

        % 1. 出力用の配列をコピー
        pha_diff_with_min_line_rgb = pha_diff_rgb;

        detected_line_color = ([255, 0,0]);
        color_to_set = reshape(uint8(detected_line_color), [1, 1, 3]);

        % 3. W (列数) 回ループ
        [~, W, ~] = size(pha_diff_rgb);
        for j = 1:W
            pha_diff_with_min_line_rgb(min_line(j), j, :) = color_to_set;
        end

      endif

      % ==== 保存処理 ============================================================
      fprintf('\r\x1b[Kprogress: files %d / %d phase diff images | %s | saving images...', kk - 1, numel(files), label);

      idx_start = conf.is_save_original + 1;

      if conf.is_save_pha_diff
        % --- 文字入れ処理 ---

        % 画像のサイズを取得
        [img_h, img_w, ~] = size(pha_diff_rgb);

        % 不可視のFigureを作成
        h_fig = figure('Visible', 'off');

        % ウィンドウサイズ調整
        screen_size = get(0, 'ScreenSize');
        max_h = screen_size(4) * 0.8;
        scale_factor = max_h / img_h;
        fig_w = round(img_w * scale_factor);
        fig_h = round(img_h * scale_factor);
        set(h_fig, 'Position', [100, 100, fig_w, fig_h]);

        % Axes設定
        axes('Position', [0 0 1 1]);
        imshow(pha_diff_rgb);
        hold on;

        % 1. 文字列の設定：数字を $ で囲む
        % これにより "-5" が数学記号のマイナス付きで描画される
        str_text = sprintf('$%+.2f$ mm', conf.fresnel_d);

        % 座標計算
        text_x = img_w * 0.05;
        text_y = img_h * 0.05;
        font_size_pixel = img_h * 0.5; % 0.3倍 (大きすぎる場合は 0.1 等に調整)

        % text関数：Interpreterをtexに指定
        text(text_x, text_y, str_text, ...
            'Color', 'white', ...
            'FontName', 'Times New Roman', ... % 数式部分は数式フォントになりますが、mm等はTimesになります
            'Interpreter', 'latex', ...       % TeX解釈を有効化
            'FontUnits', 'pixels', ...
            'FontSize', font_size_pixel, ...
            'VerticalAlignment', 'top', ...
            'HorizontalAlignment', 'left', ...
            'FontWeight', 'bold');

        % 画像取得とリサイズ
        drawnow;
        frame = getframe(gca);
        img_with_text = frame.cdata;

        if size(img_with_text, 1) ~= img_h || size(img_with_text, 2) ~= img_w
            img_with_text = imresize(img_with_text, [img_h, img_w], 'bicubic');
        end

        close(h_fig);

        % 保存
        imwrite(img_with_text, fullfile(outdir, sprintf('%02d_%02d_%s_phadiff%s.png', kk, k+idx_start-1, label, conf.add_endname_to_file)));
        idx_start = idx_start + length(fields);
      endif

      if conf.is_save_amp_diff
        imwrite(amp_diff    , fullfile(outdir, sprintf('%02d_%02d_%s_ampdiff%s.png', kk, k+idx_start-1, label, conf.add_endname_to_file)));
        idx_start = idx_start + length(fields);
      endif
      if conf.is_save_ins_diff
        imwrite(ins_diff    , fullfile(outdir, sprintf('%02d_%02d_%s_insdiff%s.png', kk, k+idx_start-1, label, conf.add_endname_to_file)));
        idx_start = idx_start + length(fields);
      endif
      if conf.is_save_ins
        imwrite((amp_struct.(label)).^2, fullfile(outdir, sprintf('%02d_%02d_%s_ins%s.png', kk, k+idx_start-1, label, conf.add_endname_to_file)));
        idx_start = idx_start + length(fields);
      endif
      if conf.is_save_transmittance
        imwrite(trans_rate, fullfile(outdir, sprintf('%02d_%02d_%s_transmittance%s.png', kk, k+idx_start-1, label, conf.add_endname_to_file)));
        idx_start = idx_start + length(fields);
      endif
      if conf.is_save_auto_detection
        imwrite(pha_diff_with_min_line_rgb, fullfile(outdir, sprintf('%02d_%02d_%s_ditected_min_line%s.png', kk, k+idx_start-1, label, conf.add_endname_to_file)));
        idx_start = idx_start + length(fields);
      endif

      fprintf('\r\x1b[Kprogress: files %d / %d phase diff images | %s | ', kk - 1, numel(files), label);

      if conf.is_save_visualize
        h = figure("visible", "off");
        subplot(2, 5, 1)
        imshow((pha_base.(label)+pi)/(2*pi))
        title("pha_base")
        subplot(2, 5, 2)
        pha_base_group = unwrapped_pha_base.(label) - pha_base.(label);
        imshow(unwrapped_pha_base.(label) - pha_base.(label))
        title("grouping")
        subplot(2, 5, 3)
        imshow((unwrapped_pha_base.(label)-min(min(unwrapped_pha_base.(label))))/(2*pi))
        title("unwrapped\npha base")
        subplot(2, 5, 6)
        imshow((pha_struct.(label)+pi)/(2*pi))
        title("pha")
        subplot(2, 5, 7)
        imshow(normalize_image(unwrapped_pha - pha_struct.(label)))
        title("grouping")
        subplot(2, 5, 8)
        imshow((unwrapped_pha-min(min(unwrapped_pha)))/(2*pi))
        title("unwrapped\npha")
        print(h, fullfile(outdir, sprintf('%02d_%02d_%s_process.png', kk, k+idx_start-1, label)), "-dpng");
        idx_start = idx_start + length(fields);

        close(h);
      endif

      % =======================================================================
      % フレネル変換による切り貼り処理
      if conf.fresnel_distances != 0
        % 最初のループ (compare_index=1) の時だけ、格納用の空画像を作成する
        % (サイズをpha_diff_rgbに合わせる)
        if compare_index == 1
            [H, W, C] = size(pha_diff_rgb); % 高さ, 幅, チャンネル数を取得
            focused_pha_diff_rgb.(label) = zeros(H, W, C, class(pha_diff_rgb));
        end

        % このサイクルで担当する「横の範囲（列）」を計算
        % 画像の幅 W を N 等分．端数が出ても隙間なく埋めるためfloorを．
        x_start = floor((compare_index-1) * W / length(conf.fresnel_distances)) + 1;
        x_end   = floor(compare_index * W / length(conf.fresnel_distances));

        % 計算した範囲だけ生成された画像から切り取って埋め込む
        focused_pha_diff_rgb.(label)(:, x_start:x_end, :) = pha_diff_rgb(:, x_start:x_end, :);

        filename = fullfile(outdir, sprintf('%02d_%02d_%s_focused_pha_diff.png', kk, k+idx_start-1, label));
        imwrite(focused_pha_diff_rgb.(label), filename);
      end
    end
    fprintf('\r\x1b[Kprogress: files %d / %d', kk, numel(files));

    % ==== 保存処理終了 =========================================================
  end
  fprintf('\n\n');
end
fprintf('\n');
