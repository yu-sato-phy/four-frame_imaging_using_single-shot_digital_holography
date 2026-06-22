function peak_coords = get_peaks(image_file, runs, conf)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 受け取ったファイル名からファイルを展開し，格納されている画像に対して周波数空間におけるピークを検出
  % 周波数空間を上方45%の領域の最大値*1/5の値で二値化
  % 20250504からglobal変数化
  % temp_0910から構造体化
  % Detected Peaksは 1つ目に検出したピーク位置，2つ目にその点と画像の平均輝度との比を示す．
  % 気づいたらifだらけになっているが，動いているのでヨシ!!👉
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % yが中心付近の場合に弾く領域 (単位: 割合)
  prohibited_area = 0.05;

  pkg load image;                   # 画像処理用のパッケージを読み込む
  pkg load signal;                  # 信号処理用のパッケージを読み込む

  peak_coords = struct();

  # スペクトル周波数領域でのピーク位置検出を行う
  % base_fileに対してのみ実行

  [filepath,file_name,ext] = fileparts(image_file);
  % 表示用
  base = sprintf("%s.tif", file_name);
  printf('base: %s\n', base);
  if(runs > 0)
    printf('runs: %d\n', runs);
  end

  # 画像読み込み
  row_image = imread(image_file);

  if(conf.is_fill_overexposure)
    image = fill_overexposure(row_image);
  else
    image = row_image;
  end

  img_struct = separate_pol(image);        # 偏光分離された画像を読み込み

  % 各偏光角毎に処理
  for kk = 1: max(1, length(conf.pol_angles))
    max_length_angle_str = 1;
    angle = conf.pol_angles(kk);       % 45, 135, "r" 等
    angle_str = num2str(angle);
    I = img_struct.(angle_str);
    [N, ~] = size(I);

    if(conf.is_Hanning_window_for_image)
      % 元画像にハニングウィンドウを導入
      % 1. 縦方向と横方向の1Dハニングウィンドウを生成
      %    hanning関数は列ベクトルを返す
      hanning_rows = hanning(N);
      hanning_cols = hanning(N);
      % 2. 外積で2Dウィンドウを生成
      %    列ベクトル(rows x 1)と行ベクトル(1 x cols)の行列積で実現
      window = hanning_rows * hanning_cols'; % hanning_colsを転置(')して行ベクトルにする
      I = I .* window;
    end

    Imax = max(max(I));                            # 最大輝度を取得（正規化用）
    I_norm  = double(I)/double(Imax);        # 正規化してdouble型へ変換
    I_shifted  = fftshift(I_norm);                 # 中心を原点にシフト
    F = fftshift((fft2(I_shifted)));                      # 2次元FFT + シフト
    FA = abs(F);                                 # 振幅スペクトル（強度）

    # 1. 正規化してスムージング（ぼかし）
    FA_norm  = FA / max(max(FA));
    FA_blur  = imsmooth( FA_norm, "Gaussian", sigma = 6);

    % 2. 閾値で明るい領域だけ抽出
    [m, n] = size(FA_blur);  % 画像サイズ
    FA_b_sample_region  = FA_blur(1:floor(m*0.45), :);  % 上方45%だけ切り出し
    FA_max_value = max(FA_b_sample_region(:));  % 上方45%の最大値

    FA_thresh  = FA_max_value/5;  % 最大値の1/5
    BW = FA_blur > FA_thresh;  % 二値化

    % 3. ラベリング
    BW_label  = bwlabel(BW);

    % 4. 各ラベル（ブロック）の重心を求める
    props = regionprops(BW_label, 'Centroid');

    % 5. 重心座標を取り出し
    centroids = cat(1, props.Centroid);

    % 7. 座標の再定義
    p_index_01 = 1;
    p_index_02 = 2;
    % 範囲に収まるように (簡略化できそう(ただyが真ん中に))
    if(length(centroids) >= 5)
      if((centroids(p_index_01, 2) <= N/2 + N*prohibited_area) && (centroids(p_index_01, 2) >= N/2 - N*prohibited_area))
        p_index_01 = p_index_01 + 1;
        p_index_02 = p_index_02 + 1;
      end
    end
    if(length(centroids) >= 7)
      if((centroids(p_index_01, 2) <= N/2 + N*prohibited_area) && (centroids(p_index_01, 2) >= N/2 - N*prohibited_area))
        p_index_01 = p_index_01 + 1;
        p_index_02 = p_index_02 + 1;
      end
    end

    if((centroids(p_index_02, 2) <= N/2 + N*prohibited_area) && (centroids(p_index_02, 2) >= N/2 - N*prohibited_area))
      p_index_02 = min(p_index_02 + 1, ceil(length(centroids)/2));
    end
    if((centroids(p_index_02, 2) <= N/2 + N*prohibited_area) && (centroids(p_index_02, 2) >= N/2 - N*prohibited_area))
      p_index_02 = min(p_index_02 + 1, ceil(length(centroids)/2));
    end

    pre_x01 = centroids(p_index_01,1);
    pre_y01 = centroids(p_index_01,2);
    pre_x02 = centroids(p_index_02,1);
    pre_y02 = centroids(p_index_02,2);

    % 下半分のは上に持ってくる．
    if(pre_y01 >= N/2)
      pre_x01 = N/2 -1*(pre_x01 - N/2);
      pre_y01 = N/2 -1*(pre_y01 - N/2);
    end
    if(pre_y02 >= N/2)
      pre_x02 = N/2 -1*(pre_x02 - N/2);
      pre_y02 = N/2 -1*(pre_y02 - N/2);
    end

    temp_dist = sqrt((pre_x01 - pre_x02)^2+(pre_y01 - pre_y02)^2);
    if(temp_dist <= N/100)
      pre_x02 = centroids(ceil(length(centroids)/2),1);
      pre_y02 = centroids(ceil(length(centroids)/2),2);
    end

    pre_dist = sqrt((pre_x01 - pre_x02)^2+(pre_y01 - pre_y02)^2);
    pre_radius  = min(N/4, pre_dist/2);               % 0930 中心を拾わないように近辺で重心を取る

    % 8. ピクセルベースの窓関数の作製
    [h, w] = size(FA);        % サイズを取得
    [xgrid, ygrid] = meshgrid(1:w, 1:h);    % インデックス配列を作成
    % 中心からの距離を計算 (ピーク探索は半径の5分の1で探索)
    wind01 = sqrt((xgrid - pre_x01).^2 + (ygrid - pre_y01).^2) < pre_radius/5;
    wind02 = sqrt((xgrid - pre_x02).^2 + (ygrid - pre_y02).^2) < pre_radius/5;

    %{
    % 偏光ピーク検出処理 ------------------------
    FAmax01 = max(max(FA(wind01)))                      # 条件内の最大値を取得
    [x01, y01] = find(FA == FAmax01,1)                 # 最大値の座標を取得

    FAmax02 = max(max(FA(wind02)))                      # 条件内の最大値を取得
    [x02, y02] = find(FA == FAmax02,1)                  # 最大値の座標を取得
    %}

    x01 = round(sum(wind01 .* ygrid .* FA) / sum(wind01 .* FA)) + conf.adjustX01;
    y01 = round(sum(wind01 .* xgrid .* FA) / sum(wind01 .* FA)) + conf.adjustY01;
    x02 = round(sum(wind02 .* ygrid .* FA) / sum(wind02 .* FA)) + conf.adjustX02;
    y02 = round(sum(wind02 .* xgrid .* FA) / sum(wind02 .* FA)) + conf.adjustY02;

    if(y01 > y02)
      temp_x = x01;
      temp_y = y01;
      x01 = x02;
      y01 = y02;
      x02 = temp_x;
      y02 = temp_y;
    end

    dist01 = sqrt((x01 - x02)^2+(y01 - y02)^2);
    dist02 = sqrt((x01 - x02)^2+(y01 - (y02 - N))^2);     % 1001追加
    dist03 = sqrt((x01 - x02)^2+((y01 - N) - y02)^2);     % 1001追加
    radius = min([dist01, dist02, dist03])/2;
    if(radius != dist01/2)
      temp_x = x01;
      temp_y = y01;
      x01 = x02;
      y01 = y02;
      x02 = temp_x;
      y02 = temp_y;
    end
    radius = radius * conf.radius_rate_of_window;         % 0922追加

    if kk == 1
      fprintf('-- Detected Peaks\n')
    endif
    if(length(conf.pol_angles) >= 2)
      printf('%3s | ', angle_str);
    else
      printf('%s | ', angle_str);
    end

    max_intensities = max(FA(:));
    interference_rate01 = FA(x01, y01) / max_intensities * 100;
    interference_rate02 = FA(x02, y02) / max_intensities * 100;

    printf('p1: (%d, %d) [%.3f %%] | ', x01, y01, interference_rate01);                   % 0923変更
    printf('p2: (%d, %d) [%.3f %%] | ', x02, y02, interference_rate02);

    resolution = conf.pixel_size * N / (2*radius);
    printf('resolution: %.1f um\n', resolution*1000);

    xmax = [x01, x02];
    ymax = [y01, y02];

    key01 = sprintf('%s_01', angle_str);
    key02 = sprintf('%s_02', angle_str);

    # 辞書にまとめる
    peak_coords.(key01) = [x01, y01, radius];
    % peak_coords.(key01) = [round(pre_y01), round(pre_x01), radius];
    peak_coords.(key02) = [x02, y02, radius];
    % peak_coords.(key02) = [round(pre_y02), round(pre_x02), radius];

    % 可視化
    if conf.is_get_peaks_view
      figure(3*(kk-1) + 1);
      % imshow(FA_norm*500);
      % 周波数を対数で表示
      log_FA = log10(1 + FA);
      imshow(log_FA / max(max(log_FA)));
      hold on;
      ax = axis; % 現在の座標軸の範囲を保存
      plot(ymax(:), xmax(:), 'r+', 'MarkerSize', 2);
      % 偏光カメラ時の範囲
      if(conf.pol_angles == 'r')
        rectangle('Position', [floor(h/4), floor(w/4), floor(h/2), floor(w/2)], 'EdgeColor', 'w', 'LineWidth', 0.2);
      end
      for k = 1:2
        text(ymax(k) + 5, xmax(k)+35, sprintf("p0%d\\_%s", k, angle_str), "FontSize", 8, "Color", "red");
        if(conf.is_croped_circle || conf.is_crop == false)
          % 円の窓関数で切りとる
          theta = linspace(0, 2*pi, 100);
          plot(+0 + ymax(k) + radius * sin(theta), +0 + xmax(k) + radius * cos(theta), 'Color', 'yellow', 'LineWidth', 0.5);
          plot(+h + ymax(k) + radius * sin(theta), +0 + xmax(k) + radius * cos(theta), 'Color', 'yellow', 'LineWidth', 0.5);
          plot(-h + ymax(k) + radius * sin(theta), +0 + xmax(k) + radius * cos(theta), 'Color', 'yellow', 'LineWidth', 0.5);
          plot(+0 + ymax(k) + radius * sin(theta), +w + xmax(k) + radius * cos(theta), 'Color', 'yellow', 'LineWidth', 0.5);
          plot(+0 + ymax(k) + radius * sin(theta), -w + xmax(k) + radius * cos(theta), 'Color', 'yellow', 'LineWidth', 0.5);
          plot(+h + ymax(k) + radius * sin(theta), +w + xmax(k) + radius * cos(theta), 'Color', 'yellow', 'LineWidth', 0.5);
        end
        if(conf.is_crop)
          % 長方形で切りとる
          rectangle('Position', [+0 + ymax(k)-radius, +0 + xmax(k)-radius, 2*radius, 2*radius], 'EdgeColor', 'g', 'LineWidth', 0.5);
          rectangle('Position', [+h + ymax(k)-radius, +0 + xmax(k)-radius, 2*radius, 2*radius], 'EdgeColor', 'g', 'LineWidth', 0.5);
          rectangle('Position', [-h + ymax(k)-radius, +0 + xmax(k)-radius, 2*radius, 2*radius], 'EdgeColor', 'g', 'LineWidth', 0.5);
          rectangle('Position', [+0 + ymax(k)-radius, +w + xmax(k)-radius, 2*radius, 2*radius], 'EdgeColor', 'g', 'LineWidth', 0.5);
          rectangle('Position', [+0 + ymax(k)-radius, -w + xmax(k)-radius, 2*radius, 2*radius], 'EdgeColor', 'g', 'LineWidth', 0.5);
          rectangle('Position', [+h + ymax(k)-radius, +w + xmax(k)-radius, 2*radius, 2*radius], 'EdgeColor', 'g', 'LineWidth', 0.5);
        end
      end

      axis(ax); % 保存しておいた座標軸の範囲を再適用
      [img_h, img_w] = size(log_FA);
      margin_x = img_w * 0.02;
      margin_y = img_h * 0.02;
      axis([0.5 - margin_x, img_w + 0.5 + margin_x, 0.5 - margin_y, img_h + 0.5 + margin_y]);

      title(sprintf('Detected Centers (pol=%s)', angle_str));
    end

    if(conf.is_show_expand_peaks)
      figure(2)
      for k = 1: 2
        subplot(conf.num_object_lights, length(conf.pol_angles), 2*(kk - 1) + k)
        log_FA = log10(1 + FA);
        imshow(log_FA / max(max(log_FA)));
        hold on;
        view_size = 30;
        plot(ymax(k), xmax(k), 'r+', 'MarkerSize', 5);
        axis([ymax(k) - view_size/2, ymax(k) + view_size/2, xmax(k) - view_size/2, xmax(k) + view_size/2]);
        set(gca, 'fontsize', 20)
        title(sprintf('%s %02d', angle_str, k));
      end
    end

    if(conf.is_radial_profile_of_FFT)
      % 強度分布グラフ表示
      % --- ここからが本処理 ---

      % 1. 画像のサイズと中心座標を取得
      [rows, cols] = size(log_FA);
      center_row = floor(rows / 2) + 1;
      center_col = floor(cols / 2) + 1;

      % 2. 各ピクセルの中心からの距離マップを作成
      [X, Y] = meshgrid(1:cols, 1:rows);
      dist_map = sqrt((X - center_col).^2 + (Y - center_row).^2);

      % 3. 距離を整数に丸めて、どの距離「ビン」に属するかを決定
      rounded_dist_map = round(dist_map);

      % 4. 各距離ビンごとに平均と最大を計算
      max_radius = max(rounded_dist_map(:)); % 最大距離を求める
      radii = 0:max_radius; % 横軸のデータ（0から最大距離まで）

      avg_intensities = zeros(1, length(radii)); % 結果を格納する配列を初期化
      max_intensities = zeros(1, length(radii));

      for r = 0:max_radius
          % 現在の距離rに属するピクセルのマスクを作成
          mask = (rounded_dist_map == r);

          % そのマスクに該当する強度値を取得
          values_at_r = log_FA(mask);

          if ~isempty(values_at_r)
              avg_intensities(r + 1) = mean(values_at_r);
              max_intensities(r + 1) = max(values_at_r);
          end
      end

      filter_window_size = 5;
      smoothed_max_intensities = medfilt1(max_intensities, filter_window_size);

      % 5. グラフにプロット
      figure(3*(kk-1) + 2);
      plot(radii, avg_intensities, 'b-', 'LineWidth', 1); % 平均値を青線でプロット
      hold on;
      plot(radii, max_intensities, 'r-', 'LineWidth', 1, 'Color', [1 0.6 0.6]);
      plot(radii, smoothed_max_intensities, 'g-', 'LineWidth', 1);
      hold off;

      grid on;
      title('Radial Profile of FFT Magnitude', 'FontSize', 12);
      xlabel('Distance from Center (pixels)');
      ylabel('Log Intensity');
      legend('Average Intensity', 'Maximum Intensity', '(Smoothed)', 'FontSize', 11);
      xlim([0, max_radius]); % 横軸の範囲を0から最大距離までに設定
      ylim([0, max(max(log_FA))]);
    endif
  end
end

