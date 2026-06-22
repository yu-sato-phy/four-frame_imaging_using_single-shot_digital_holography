function img_colorbar = get_colorbar_image(conf, cmap)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % conf内で指定された位相差の最大値最小値からカラーバーを作成
  % 適当な画像を生成し，カラーバーを生成
  % たまにカラーバーが太って出力されるが発生条件等未解決
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % Figure作成（サイズ明示）
  f = figure('visible', 'off', 'Position', [100, 100, 120, 600]);

  % グラデーション画像を作成
  N = 256;
  pha_diff_min = conf.pha_diff_min;
  pha_diff_max = conf.pha_diff_max;
  data = linspace(pha_diff_min, pha_diff_max, N)';
  img = repmat(data, 1, 10);  % 幅10pxの縦グラデーション

  % 描画
  imagesc([0, 1], [pha_diff_min, pha_diff_max], img);
  colormap(cmap);
  ax = gca;
  set(ax, 'YDir', 'normal');
  set(ax, 'XTick', []);
  set(ax, 'YTickLabel', []);
  set(ax, 'Position', [0.2 0.05 0.2 0.9]);

  % Ticks作成
  ticks = generate_ticks_with_zero(pha_diff_min, pha_diff_max);

  % ラベルを右側に追加
  for i = 1:length(ticks)
    text(1.5, ticks(i), num2str(ticks(i), '%+.2f'), ...
         'HorizontalAlignment', 'left', ...
         'VerticalAlignment', 'middle', ...
         'FontSize', 18);
  end

  % 画像を取得
  drawnow;
  frame = getframe(f);
  img_colorbar = frame.cdata;

  % 図を閉じる
  close(f);
end

function ticks = generate_ticks_with_zero(min_val, max_val)
  % 候補となるステップサイズ
  steps = [1, 0.5, 0.2, 0.1, 0.05, 0.02, 0.01, 0.005, 0.002, 0.001];

  for step = steps
    min_tick = ceil(min_val / step) * step;
    max_tick = floor(max_val / step) * step;
    ticks = min_tick:step:max_tick;

    % check: 0含む, 範囲内, 数量十分
    if any(abs(ticks) < step/2) && ...
       all(ticks >= min_val - 1e-8) && ...
       all(ticks <= max_val + 1e-8) && ...
       length(ticks) >= 6 && length(ticks) <= 12
      return;
    endif
  endfor

  % fallback
  ticks = linspace(min_val, max_val, 7);
endfunction

