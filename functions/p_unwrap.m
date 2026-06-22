function unwrapped_image = p_unwrap(wrap_image, conf)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % conf.num_unwrapsの数だけunwrap_integer_offsets_robust()関数にてアンラップを実行
  % 各回におけるアンラップ実行処理を画像表示可能
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  is_view = conf.is_unwrap_visualize;
  num_unwraps = conf.num_unwraps;

  process_image = wrap_image;
  if is_view
    figure();
    subplot(num_unwraps,3,1);
    imagesc(wrap_image); axis image; colormap(gca, 'gray'); colorbar;
    title('Wrapped Phase');
  endif

  for i = 1: num_unwraps
    k = unwrap_integer_offsets_robust_sl(process_image);
    process_image = process_image + 2*pi*double(k);
    if is_view
      subplot(num_unwraps, 3, 3*i-1)
      imagesc(k); axis image; colormap(gca, 'jet');; colorbar;
      title(sprintf('Region Grouping%02d', i));
      subplot(num_unwraps, 3, 3*i)
      imagesc(process_image); axis image; colormap(gca, 'gray'); colorbar;
      title(sprintf('Unwrapped Phase%02d', i));
    endif
  end
  unwrapped_image = process_image;
end
