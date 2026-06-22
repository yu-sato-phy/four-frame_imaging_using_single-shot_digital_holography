function [amp_struct, pha_struct] = process_image(file, peak_coords, conf)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % それぞれのlabel(r_01, r_02や45_01, 45_02等)に対応する強度と位相を返す．
  %　mkimg_amp_pha()関数を用いて画像を生成し，それぞれのlabelに格納
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  num_object_lights = conf.num_object_lights;
  pol_angles = conf.pol_angles;
  is_show_FFT = conf.is_show_FFT;
  is_Hanning = conf.is_Hanning_window_for_image;
  is_fill = conf.is_fill_overexposure_process;
  is_crop = conf.is_crop;

  [~, name, ~] = fileparts(file);

  row_image = imread(file);

  if(conf.is_fill_overexposure_process)
    image = fill_overexposure(row_image);
  else
    image = row_image;
  end

  pol_struct = separate_pol(image);

  amp_struct = struct();
  pha_struct = struct();

  % 偏光角による繰り返し
  for kk2 = 1:max(1, length(pol_angles))
    angle = pol_angles(kk2);
    angle_str = num2str(angle);
    % 角度ズレによる繰り返し
    for point = 1:conf.num_object_lights
      label = sprintf('%s_%02d', angle_str, point);
      coord = peak_coords.(label);

      [amp, pha] = mkimg_amp_pha(pol_struct.(angle_str), coord(1), coord(2), coord(3), conf);

      amp_struct.(label) = amp;
      pha_struct.(label) = pha;
    end
  end
end

