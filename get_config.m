function conf = get_config()
  % 各種設定

  conf = struct();

  % 1. 表示 ====================================================================
    conf.is_get_peaks_view             = true; % FFT画像と検出されたピークの位置の表示
    conf.is_show_expand_peaks          = true; % 周波数のピーク位置の表示

    conf.is_radial_profile_of_FFT      = false; % 周波数領域における動径特性グラフの表示
    conf.is_fitting_radial_propaties   = false; % 動径特性のフィッティング
    conf.is_show_FFT                   = false; % 未実装
    conf.is_fill_overexposure_process  = false; % 白とび補完プロセスの画像化
    conf.is_unwrap_visualize           = false; % アンラップ過程の表示

  % 2. compare用保存設定 ========================================================
    conf.is_save_visualize             = false; % 実行の過程の保存
    conf.is_save_original              = false; % 元画像の保存
    conf.is_save_pha_diff              = true; % 位相差画像の保存
    conf.pha_diff_max                  = +0.20; % 位相表示範囲 (最大値)
    conf.pha_diff_min                  = -0.20; % 位相表示範囲 (最小値)
    conf.is_save_amp_diff              = false; % 振幅差画像の保存
    conf.gain_amp_diff                 = 5; % 振幅差画像のゲイン
    conf.is_save_ins_diff              = true; % 強度差画像の保存
    conf.gain_ins_diff                 = 3; % 強度差画像のゲイン
    conf.is_save_ins                   = false; % 強度画像の保存
    conf.is_save_transmittance         = false; % 透過率画像の保存
    conf.is_save_auto_detection        = false; % 自動プラズマ検知機構

    conf.add_endname_to_file           = ''; % ファイルの末尾に共通の名前を追加する．

  % 3. prepare用の保存設定 ==========================================================
    conf.is_new_file_when_same         = true; % 同名のファイルを処理するときに出力を新規ファイルにする
    conf.save_pha_in_prepare           = true; % prepare内で位相画像の保存
    conf.save_amp_in_prepare           = false; % prepare内で振幅画像の保存
    conf.save_ins_in_prepare           = false; % prepare内で強度画像の保存

    conf.phase_noise_checker           = true; % 位相画像のノイズを測定する

  % 4. ディレクトリ操作 =============================================================
    conf.image_dir                     = 'images'; % inputのディレクトリ
    conf.outdir_compare                = 'output'; % compare時の出力ディレクトリ
    conf.outdir_prepare                = 'IMG_prepare'; % prepar e時の出力ディレクトリ

  % 5. 画像処理 =================================================================
    conf.num_bases                     = 10; % 平均をとるベース画像の枚数
    conf.num_compares                  = 1; % compare時の再生画像の枚数

    conf.compare_cycles                = 0; % compare内での周回数 (0で最大ループ)
    conf.is_fill_overexposure          = true; % 白とびを埋める
    conf.is_Hanning_window_for_image   = false; % 元画像にハニング窓をかける
    conf.is_crop                       = true; % 画像サイズそのもので切り取る
    conf.is_croped_circle              = true; % さらに円形で切りとる．
    conf.radius_rate_of_window         = 1.0;   % 窓関数の半径を調整する．
    conf.power_of_median_for_out_Im    = 2;     % 出力のメディアンフィルタの強さ

    conf.num_unwraps                   = 3;     % ラップ処理回数

  % 6. 物理パラメータ ==============================================================
    conf.wavelength                    = 800e-6; % 波長

    conf.adjustX01                     = 0;    % 周波数中心手動補正
    conf.adjustX02                     = 0;    % (Xを高いと上方へ傾く)
    conf.adjustY01                     = -0;    % (Yが高いと左方へ傾く)
    conf.adjustY02                     = -0;    %

    conf.zoom_ratio                    = 15; % レンズ系のズーム倍率
    conf.fresnel_d                     = 0.00; % フレネル変換用伝搬距離 (単位: mm)
    conf.fresnel_distances             = [0.00: 0.02: 0.34]; % 複数入力でフレネル変換ループ
    conf.fresnel_distances             = []; % 複数入力でフレネル変換ループ

    conf.num_object_lights             = 2;     % 0922時点で ( <= 2 )
    conf.pol_angles                    = [45, 135]; % 偏光方向の画像を取り出して処理 入力なしでrandom偏光（入力例 [45, 135], ['r'] ）
    % conf.pol_angles                    = ['r']; % 偏光方向の画像を取り出して処理 入力なしでrandom偏光（入力例 [45, 135], ['r'] ）

    conf.pixel_size                    = 3.45e-3 * length(conf.pol_angles); % ピクセルサイズ (偏光カメラで2倍のサイズ)

end
