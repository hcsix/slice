#!/bin/bash

# 检测 ImageMagick 是否安装
if ! command -v magick &> /dev/null; then
    echo "ImageMagick 未安装，请先安装 ImageMagick。"
    exit 1
fi

# 启用通配符匹配不区分大小写
shopt -s nocaseglob

# 启用通配符没有匹配到任何文件时，数组为空
shopt -s nullglob

# 手动输入参数
read -p "请输入输入图片文件路径 (默认: 当前路径/input_image.png): " input_file

# 如果输入图片文件路径为空，遍历当前文件夹下的图片文件并提供选择
if [ -z "$input_file" ]; then
    image_files=(*.{png,jpg,jpeg,gif,tiff})
    if [ ${#image_files[@]} -eq 0 ]; then
        echo "当前文件夹下没有找到任何图片文件。"
        exit 1
    fi

    echo "当前文件夹下的图片文件列表:"
    for i in "${!image_files[@]}"; do
        echo "$((i+1)). ${image_files[i]}"
    done

    read -p "请选择一个图片文件 (输入数字): " choice

    # 校验用户输入是否为有效的数字
    while ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -le 0 ] || [ "$choice" -gt "${#image_files[@]}" ]; do
        read -p "无效的选择，请重新输入一个数字: " choice
    done

    input_file="${image_files[$((choice-1))]}"
else
    # 如果用户输入了路径，检查文件是否存在
    if [ ! -f "$input_file" ]; then
        echo "文件 $input_file 不存在。"
        exit 1
    fi
fi

read -p "请输入输出图片目录 (默认: 当前路径/output_images): " output_dir

# 设置默认值
input_file=${input_file:-"input_image.png"}
output_dir=${output_dir:-"output_images"}

# 创建输出目录，如果不存在
mkdir -p "$output_dir"

# 获取输入图片的宽高
image_width=$(magick identify -format "%w" "$input_file")
image_height=$(magick identify -format "%h" "$input_file")

# 第一步：裁切无用边距
echo "第一步：裁切无用边距"

# 输入相对于原图缩放后的图片的长和宽
read -p "请输入缩放后的图片宽度 (留空则根据高度计算): " scaled_width
read -p "请输入缩放后的图片高度 (留空则根据宽度计算): " scaled_height

# 校验缩放后的图片宽度和高度是否至少有一个不为空
if [ -z "$scaled_width" ] && [ -z "$scaled_height" ]; then
    echo "缩放后的图片宽度和高度不能同时为空，请重新输入。"
    read -p "请输入缩放后的图片宽度 (留空则根据高度计算): " scaled_width
    read -p "请输入缩放后的图片高度 (留空则根据宽度计算): " scaled_height
fi

# 根据输入计算缩放比例
if [ -z "$scaled_width" ]; then
    # 根据高度计算宽度
    scaled_width=$(printf "%.0f" "$(echo "$scaled_height * $image_width / $image_height" | bc)")
elif [ -z "$scaled_height" ]; then
    # 根据宽度计算高度
    scaled_height=$(printf "%.0f" "$(echo "$scaled_width * $image_height / $image_width" | bc)")
fi

# 校验缩放后的图片宽度和高度是否为有效的数字
while ! [[ "$scaled_width" =~ ^[0-9]+$ ]] || ! [[ "$scaled_height" =~ ^[0-9]+$ ]]; do
    echo "缩放后的图片宽度和高度必须为数字，请重新输入。"
    read -p "请输入缩放后的图片宽度 (留空则根据高度计算): " scaled_width
    read -p "请输入缩放后的图片高度 (留空则根据宽度计算): " scaled_height

    # 校验缩放后的图片宽度和高度是否至少有一个不为空
    if [ -z "$scaled_width" ] && [ -z "$scaled_height" ]; then
        echo "缩放后的图片宽度和高度不能同时为空，请重新输入。"
        read -p "请输入缩放后的图片宽度 (留空则根据高度计算): " scaled_width
        read -p "请输入缩放后的图片高度 (留空则根据宽度计算): " scaled_height
    fi

    # 根据输入计算缩放比例
    if [ -z "$scaled_width" ]; then
        # 根据高度计算宽度
        scaled_width=$(printf "%.0f" "$(echo "$scaled_height * $image_width / $image_height" | bc)")
    elif [ -z "$scaled_height" ]; then
        # 根据宽度计算高度
        scaled_height=$(printf "%.0f" "$(echo "$scaled_width * $image_height / $image_width" | bc)")
    fi
done

# 输入在缩放后图片上的坐标点
read -p "请输入左上角横坐标 (x1) 和右下角横坐标 (x2) 用空格隔开: " x1_scaled x2_scaled
read -p "请输入左上角纵坐标 (y1) 和右下角纵坐标 (y2) 用空格隔开: " y1_scaled y2_scaled

# 校验坐标点是否为有效的数字
while ! [[ "$x1_scaled" =~ ^[0-9]+$ ]] || ! [[ "$y1_scaled" =~ ^[0-9]+$ ]] || ! [[ "$x2_scaled" =~ ^[0-9]+$ ]] || ! [[ "$y2_scaled" =~ ^[0-9]+$ ]]; do
    echo "坐标点必须为数字，请重新输入。"
    read -p "请输入左上角横坐标 (x1) 和右下角横坐标 (x2) 用空格隔开: " x1_scaled x2_scaled
    read -p "请输入左上角纵坐标 (y1) 和右下角纵坐标 (y2) 用空格隔开: " y1_scaled y2_scaled
done

# 校验坐标点是否合理
while [ "$x2_scaled" -le "$x1_scaled" ] || [ "$y2_scaled" -le "$y1_scaled" ]; do
    echo "右下角坐标必须大于左上角坐标，请重新输入。"
    read -p "请输入左上角横坐标 (x1) 和右下角横坐标 (x2) 用空格隔开: " x1_scaled x2_scaled
    read -p "请输入左上角纵坐标 (y1) 和右下角纵坐标 (y2) 用空格隔开: " y1_scaled y2_scaled
done

# 计算在原图上的坐标点
x1=$(printf "%.0f" "$(echo "$x1_scaled * $image_width / $scaled_width" | bc)")
y1=$(printf "%.0f" "$(echo "$y1_scaled * $image_height / $scaled_height" | bc)")
x2=$(printf "%.0f" "$(echo "$x2_scaled * $image_width / $scaled_width" | bc)")
y2=$(printf "%.0f" "$(echo "$y2_scaled * $image_height / $scaled_height" | bc)")

# 计算裁切宽度和高度
crop_width=$((x2 - x1))
crop_height=$((y2 - y1))

# 执行裁切命令
magick "$input_file" -crop ${crop_width}x${crop_height}+${x1}+${y1} +repage "$output_dir/trimmed_image.png"

# 检查 magick 命令是否执行成功
if [ $? -ne 0 ]; then
    echo "裁切操作失败，请检查输入参数。"
    exit 1
fi

echo "图片切边完成，生成的处理图路径: $output_dir/trimmed_image.png"