function k = unwrap_integer_offsets_robust(phi_wrap)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 2次元アンラップ関数
  % ラップされた位相に対して整数オフセットを戻す
  % 各差分に対して2piで丸めたのちにラップ位相のラプラシアンを生成．
  % DCTで高速処理
  % - 使用例 -
  % k = unwrap_integer_offsets_robust(phi_wrap);
  % phi_unwrapped = phi_wrap + 2 * pi * k;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  pkg load signal
  pkg load image

  [M, N] = size(phi_wrap);

  % 増加量を2piで丸めておく
  dk_x = round((phi_wrap(:, 1:end-1) - phi_wrap(:, 2:end)) / (2 * pi));
  dk_y = round((phi_wrap(1:end-1, :) - phi_wrap(2:end, :)) / (2 * pi));

  rho_k = zeros(M, N);
  rho_k(:, 1:end-1) = rho_k(:, 1:end-1) + dk_x;
  rho_k(:, 2:end) = rho_k(:, 2:end) - dk_x;
  rho_k(1:end-1, :) = rho_k(1:end-1, :) + dk_y;
  rho_k(2:end, :) = rho_k(2:end, :) - dk_y;

  dct_rho_k = dct2(rho_k);

  [wx, wy] = meshgrid(0:N-1, 0:M-1);
  denominator = 2 * cos(pi * wx / N) + 2 * cos(pi * wy / M) - 4;
  denominator(1, 1) = 1;

  dct_k = dct_rho_k ./ denominator;
  k_solved = idct2(dct_k);

  % mean(k_solved(:))を基準に合わせる
  k_final = round(k_solved - mean(k_solved(:)));

  k = int32(k_final);
end
