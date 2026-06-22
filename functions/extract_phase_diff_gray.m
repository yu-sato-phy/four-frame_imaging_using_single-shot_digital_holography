function show_pha_diff = extract_phase_diff_gray(row_pha_diff, conf)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % row_pha_diffをconfのpha_diff_min, pha_diff_maxで規格化
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  pha_diff_min = conf.pha_diff_min;
  pha_diff_max = conf.pha_diff_max;

  [H, W] = size(row_pha_diff);

  % 中心領域を取り出して平均を算出
  center_size = min(H, W)/2;
  h_start = floor(H/2 - center_size/2) + 1;
  w_start = floor(W/2 - center_size/2) + 1;
  center_region = row_pha_diff(h_start:h_start+center_size-1, w_start:w_start+center_size-1);
  center_mean = mean(mean(center_region(:)));

  % 定数成分を除去
  pha_diff = row_pha_diff - center_mean;

  % ↓ 以下を有効にすれば [-pi, pi] にラップする（wrap 有効）
  % pha_diff = mod(pha_diff + pi, 2*pi) - pi;

  % 正規化してグレースケール (0〜255)
  pha_diff_norm = (pha_diff - pha_diff_min) / (pha_diff_max - pha_diff_min);
  pha_diff_norm = min(max(pha_diff_norm, 0), 1);  % clip to [0,1]
  gray_image = uint8(pha_diff_norm * 255);

  % true: 範囲外を黒(0)にする
  % false: 範囲外をそのまま残す
  use_mask = false;

  if use_mask
    % 範囲外は黒にする
    mask = (pha_diff >= pha_diff_min) & (pha_diff <= pha_diff_max);
    show_pha_diff = uint8(zeros(H, W));
    show_pha_diff(mask) = gray_image(mask);
  else
    % 範囲外はそのまま255または0（白または黒）
    show_pha_diff = gray_image;
  end

end

