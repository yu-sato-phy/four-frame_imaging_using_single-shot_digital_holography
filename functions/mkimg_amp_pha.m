function [amp pha] = mkimg_amp_pha(image, x_peak, y_peak, radius, conf)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 受け取ったホログラム画像と中心座標から複素振幅を再構成し振幅と強度を返す
  % フーリエ変換し，シフトして切り取り，逆フーリエするのみ
  % 窓関数を円にしたり，画像自体をクロップしたりできる．
  % フレネル変換angler_spectrumを実装(25/11/21より)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  pkg load image;                   # 画像処理用のパッケージを読み込む
  pkg load signal;                  # 信号処理用のパッケージを読み込む

  if(conf.is_Hanning_window_for_image)
    % 元画像にハニングウィンドウを導入
    hanning_rows = hanning(size(image, 1));
    hanning_cols = hanning(size(image, 1));
    window = hanning_rows * hanning_cols'; % hanning_colsを転置(')して行ベクトルにする
    image = image .* window;
  end

  I_norm = image/max(max(image));
  I_shifted  = fftshift(I_norm);
  F = fftshift((fft2(I_shifted)));
  FA_norm = abs(F) / max(max(abs(F)));

  [w h] = size(image);
  dx = round(w/2) - x_peak;
  dy = round(h/2) - y_peak;
  fft_shifted = circshift(F, [dx, dy]);
  fft_shifted_abs = abs(fft_shifted)/max(max(abs(fft_shifted)));

  fft_cutted = fft_shifted;

  if(conf.is_crop == false || conf.is_croped_circle)
    % 円形窓関数を用いて切り取り．（従来）
    [xgrid, ygrid] = meshgrid(1:h, 1:w);
    wind = sqrt((xgrid - round(h/2)).^2 + (ygrid - round(w/2)).^2) < radius;
    fft_cutted = fft_cutted.*wind;
  end
  if(conf.is_crop)
    % 強引に切り取る．
    xstart = floor(w/2) - round(radius);
    xend   = floor(w/2) + round(radius);
    ystart = floor(h/2) - round(radius);
    yend   = floor(h/2) + round(radius);
    fft_cutted = fft_cutted(xstart: xend, ystart: yend);
  end

  img_reconstructed = fftshift(ifft2(ifftshift(fft_cutted)));

  % フレネル変換が来る予定
  img_fresneled = angler_spectrum(img_reconstructed, w, conf);
  % img_fresneled = Fresnel(img_reconstructed, w, conf);
  amp = abs(img_fresneled)/max(max(abs(img_fresneled)));
  pha = angle(img_fresneled);

  % amp = abs(img_reconstructed)/max(max(abs(img_reconstructed)));
  % pha = angle(img_reconstructed);

end

