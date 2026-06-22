function normed_image = normalize_image(I)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 画像を[0, 1]で規格化する
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  normed_image = (I - min(min(I))) / max(max(I - min(min(I))));
end

