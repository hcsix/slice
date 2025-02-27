#!/bin/bash

# 检测 ImageMagick 是否安装
if ! command -v magick &> /dev/null; then
    echo "ImageMagick 未安装，请先安装 ImageMagick。"
    exit 1
fi

# 手动输入参数
read -p "请输入输入图片目录: " input_dir
read -p "请输入输出图片目录: " output_dir
read -p "请输入每张小图的宽度: " width
read -p "请输入每张小图的高度: " height
read -p "请输入水平偏移初始值: " x_offset
read -p "请输入垂直偏移初始值: " y_offset

# 图片编号
image_num=1

# 创建输出目录，如果不存在
mkdir -p "$output_dir"

# 遍历输入目录中的所有图片文件
for file in "$input_dir"/*; do
    if [ -f "$file" ]; then
        # 执行裁切命令
        magick "$file" -crop ${width}x${height}+${x_offset}+${y_offset} +repage "$output_dir/output_$image_num.png"
        ((image_num++))
    fi
done

echo "所有图片裁切完毕！"