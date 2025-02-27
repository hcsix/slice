#!/bin/bash

# 检测 ImageMagick 是否安装
if ! command -v magick &> /dev/null; then
    echo "ImageMagick 未安装，请先安装 ImageMagick。"
    exit 1
fi

# 手动输入参数
read -p "请输入输入图片文件路径: " input_file
read -p "请输入输出图片目录: " output_dir
read -p "请输入每张小图的宽度: " width
read -p "请输入每张小图的高度: " height
read -p "请输入水平偏移初始值: " x_offset
read -p "请输入垂直偏移初始值: " y_offset
read -p "请输入水平方向上的小图数量: " num_cols
read -p "请输入垂直方向上的小图数量: " num_rows

# 图片编号
image_num=1

# 创建输出目录，如果不存在
mkdir -p "$output_dir"

# 获取输入图片的宽高
image_width=$(magick identify -format "%w" "$input_file")
image_height=$(magick identify -format "%h" "$input_file")

# 计算每个小图的实际裁切区域
crop_width=$((width - x_offset))
crop_height=$((height - y_offset))

# 遍历每个小图的裁切区域
for ((row=0; row<num_rows; row++)); do
    for ((col=0; col<num_cols; col++)); do
        # 计算当前小图的左上角坐标
        x=$((col * crop_width + x_offset))
        y=$((row * crop_height + y_offset))
        
        # 执行裁切命令
        magick "$input_file" -crop ${crop_width}x${crop_height}+${x}+${y} +repage "$output_dir/output_$image_num.png"
        ((image_num++))
    done
done

echo "所有图片裁切完毕！"