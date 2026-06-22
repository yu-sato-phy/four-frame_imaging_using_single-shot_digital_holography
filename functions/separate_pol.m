function pol_struct = separate_pol(image)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 入力画像を4画素単位の擬似偏光チャネルに分離し、
  % 各チャネルごとに中心から2^nの正方形に中心を変えずにクロップする
  % '0', '45', '90', '135', 'r'の5つのラベルを持つ構造体を返す．
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  I = double(image);
  Imax = max(I(:));
  I1 = I / Imax;

  % 各偏光チャネルを抽出（2x2ブロックの位置に応じて）
  I90  = downsample(downsample(I1,2)',2)';        % 右上
  I45  = downsample(downsample(I1,2)',2,1)';      % 左上
  I135 = downsample(downsample(I1,2,1)',2)';      % 右下
  I0   = downsample(downsample(I1,2,1)',2,1)';    % 左下
  I90  = I1(1:2:end, 1:2:end);		% 左上
  I45  = I1(1:2:end, 2:2:end);		% 右上
  I135 = I1(2:2:end, 1:2:end);		% 左下
  I0   = I1(2:2:end, 2:2:end);		% 右下

  % 中心クロップ関数（クロップサイズ指定）
  function out = crop_center(img, size_crop)
    [h, w] = size(img);
    start_y = floor((h - size_crop) / 2) + 1;
    start_x = floor((w - size_crop) / 2) + 1;
    out = img(start_y:start_y+size_crop-1, start_x:start_x+size_crop-1);
  end

  % 各偏光チャネルに対して共通クロップサイズを決定
  [h0, w0] = size(I0);
  min_side = min(h0, w0);
  crop_size = 2^floor(log2(min_side));  % 偏光画像の正方形サイズ

  % rand用のサイズ（2倍）
  crop_size_rand = 2 * crop_size;

  % 各チャネルに対して中心クロップを適用
  pol_struct = struct();
  pol_struct.('90')  = crop_center(I90,  crop_size);
  pol_struct.('45')  = crop_center(I45,  crop_size);
  pol_struct.('135') = crop_center(I135, crop_size);
  pol_struct.('0')   = crop_center(I0,   crop_size);

  % rand用：元画像から2倍サイズで中心クロップ（可能な最大の2^nに制限）
  [H, W] = size(I1);
  max_rand_size = 2^floor(log2(min(H, W)));  % 元画像に対する最大の2^n
  crop_size_rand = min(crop_size_rand, max_rand_size);  % 元画像超えないように
  pol_struct.('r') = crop_center(I1, crop_size_rand);
end

