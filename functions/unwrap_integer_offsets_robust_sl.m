function k = unwrap_integer_offsets_robust_sl(phi_wrap)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 2次元アンラップ関数
  % ラップされた位相に対して整数オフセットを戻す
  % 位相をexpに戻すことで位相の連続化を実行．
  % 2回微分に対して実部と虚部に気を付けることでラップ位相のラプラシアンを生成．
  % ポアソン方程式をDCTで高速処理
  % https://jp.mathworks.com/matlabcentral/fileexchange/68493-robust-2d-phase-unwrapping-algorithm
  % - 使用例 -
  % k = unwrap_integer_offsets_robust(phi_wrap);
  % phi_unwrapped = phi_wrap + 2 * pi * k;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  pkg load signal
  pkg load image

  phi1 = unwrap_TIE(phi_wrap);
  phi1 = phi1+mean2(phi_wrap)-mean2(phi1); %adjust piston
  k_final = round((phi1-phi_wrap)/2/pi);  %calculate integer K
  k = int32(k_final);

  function [phase_unwrap]=unwrap_TIE(phase_wrap)
      psi=exp(1i*phase_wrap);
      edx = [zeros([size(psi,1),1]), diff(psi, 1, 2), zeros([size(psi,1),1])];
      edy = [zeros([1,size(psi,2)]); diff(psi, 1, 1); zeros([1,size(psi,2)])];
      lap = diff(edx, 1, 2) + diff(edy, 1, 1); %calculate Laplacian using the finite difference
      rho=imag(conj(psi).*lap);   % calculate right hand side of Eq.(4) in the manuscript
   phase_unwrap = solvePoisson(rho);
  end

  function phi = solvePoisson(rho)
    % solve the poisson equation using DCT
    dctRho = dct2(rho);
    [N, M] = size(rho);
    [I, J] = meshgrid([0:M-1], [0:N-1]);
    dctPhi = dctRho ./ 2 ./ (cos(pi*I/M) + cos(pi*J/N) - 2);
    dctPhi(1,1) = 0; % handling the inf/nan value
    % now invert to get the result
    phi = idct2(dctPhi);
  end
end
