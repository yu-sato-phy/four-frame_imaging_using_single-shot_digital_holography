function filled_image = fill_overexposure(damaged_image)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 新井作
  % Baumerのカメラで生じてしまう白とびを補正する関数
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  filled_image = fill_for_one_area(damaged_image, [1112, 1205], [1129, 1227], 7);
  filled_image = fill_for_one_area(filled_image, [580, 1563], [584, 1601], 7);


  function filled_image = fill_for_one_area(original_image, top_left, bottom_right, window_size)
    % 画像内の指定された長方形領域の白飛びを補正する関数
    %
    % Args:
    %   original_image (matrix): 補正したい画像データ
    %   top_left (vector): 補正領域の左上の座標 [行, 列]
    %   bottom_right (vector): 補正領域の右下の座標 [行, 列]
    %   window_size (int): 補間時に周囲を考慮するウィンドウのサイズ

    % 画像処理パッケージをロード
    pkg load image;

    % 入力画像の型を保持し、double型に変換して計算精度を確保 (0.0 - 1.0の範囲)
    input_class = class(original_image);
    filled_image = im2double(original_image);

    % 画像のサイズ情報を取得
    [rows, cols, channels] = size(filled_image);

    % 補正したい初期の損傷マスクを作成 (長方形領域)
    initial_damage_mask = false(rows, cols);
    r1 = top_left(1);
    c1 = top_left(2);
    r2 = bottom_right(1);
    c2 = bottom_right(2);

    % 座標のバリデーション (画像範囲内に収める)
    r1 = max(1, r1); c1 = max(1, c1);
    r2 = min(rows, r2); c2 = min(cols, c2);

    % 有効な領域が存在する場合のみマスクを設定
    if (r1 <= r2 && c1 <= c2)
        initial_damage_mask(r1:r2, c1:c2) = true;
    else
        %-------- warning('指定された補正領域が画像の範囲外か無効です。補正は行われません。');
        % データ型を元の型に戻して終了
        if (strcmp(input_class, 'uint8'))
            filled_image = im2uint8(filled_image);
        elseif (strcmp(input_class, 'uint16'))
            filled_image = im2uint16(filled_image);
        end
        return;
    end

    % 現在補間が必要なピクセルを示す動的なマスク
    current_fill_mask = initial_damage_mask;

    % カーネルサイズからオフセットを計算 (window_size=5 なら offset=2)
    offset = floor(window_size / 2);

    %-------- disp('白飛び補間処理を開始します...');

    % 補間を繰り返す
    % マスク領域がなくなるか、変化がなくなるまでループ
    last_pixels_to_fill = -1;
    max_iterations = max(rows, cols); % 最大反復回数を安全に設定

    for iter = 1:max_iterations
        pixels_to_fill = sum(current_fill_mask(:));

        % 補間が完了したか、処理が停滞したらループを抜ける
        if pixels_to_fill == 0 || pixels_to_fill == last_pixels_to_fill
            %-------- disp(['補間処理が完了しました。反復回数: ', num2str(iter-1)]);
            break;
        end
        last_pixels_to_fill = pixels_to_fill;

        % 次のイテレーションで更新されるピクセルを格納する一時画像
        next_image_update = filled_image;

        % マスクの境界部分（外側に正常なピクセルがある損傷ピクセル）を見つける
        boundary_mask = current_fill_mask & ~imerode(current_fill_mask, ones(3,3));

        % 補間対象のピクセル（ここでは境界ピクセル）を走査
        [r_indices, c_indices] = find(boundary_mask);

        % 各境界ピクセルについて、周囲の有効な画素値を使って補間する
        for k = 1:numel(r_indices)
            r_center = r_indices(k);
            c_center = c_indices(k);

            % 周囲のウィンドウ範囲を計算
            r_min = max(1, r_center - offset); r_max = min(rows, r_center + offset);
            c_min = max(1, c_center - offset); c_max = min(cols, c_center + offset);

            % ウィンドウ領域を切り出し
            window_area = filled_image(r_min:r_max, c_min:c_max, :);
            window_mask = current_fill_mask(r_min:r_max, c_min:c_max);

            % ウィンドウ内の「正常な」ピクセルだけを抽出
            valid_pixels_mask = ~window_mask;

            % 有効なピクセルが存在する場合のみ平均値を計算
            if (any(valid_pixels_mask(:)))
                if (channels == 3)
                    for ch = 1:3
                        valid_channel_pixels = window_area(:, :, ch)(valid_pixels_mask);
                        next_image_update(r_center, c_center, ch) = mean(valid_channel_pixels);
                    end
                else
                    valid_pixels = window_area(valid_pixels_mask);
                    next_image_update(r_center, c_center) = mean(valid_pixels);
                end
            end
        end

        % 今回のイテレーションで計算した値を画像に反映
        filled_image = next_image_update;

        % 補間が完了したピクセル（境界部分）を current_fill_mask から除去
        current_fill_mask(boundary_mask) = false;
    end

    if sum(current_fill_mask(:)) > 0
        %-------- disp(['警告: 最大反復回数に達しましたが、', num2str(sum(current_fill_mask(:))), ' ピクセルが補間されませんでした。']);
    end

    % データ型を元の型に戻す
    if (strcmp(input_class, 'uint8'))
        filled_image = im2uint8(filled_image);
    elseif (strcmp(input_class, 'uint16'))
        filled_image = im2uint16(filled_image);
    end

    % 7. 結果を表示
    %{
    figure(1);
    subplot(1, 2, 1);
    imshow(original_image);
    title('Original Damaged Image');
    % 補正範囲を赤枠で表示
    % rectangleの引数は [x, y, width, height] なので注意 (col, row, width, height)
    width = bottom_right(2) - top_left(2);
    height = bottom_right(1) - top_left(1);
    rectangle('Position', [top_left(2), top_left(1), width, height], 'EdgeColor', 'r', 'LineWidth', 2);


    subplot(1, 2, 2);
    imshow(filled_image);
    title('filled Image');
    %}
  end



end
