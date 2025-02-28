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


# 读取并校验参数
read -p "请输入水平方向上的小图数量: " num_cols
read -p "请输入垂直方向上的小图数量: " num_rows

# 校验输入的行数和列数是否为有效的数字
while ! [[ "$num_cols" =~ ^[0-9]+$ ]] || ! [[ "$num_rows" =~ ^[0-9]+$ ]]; do
    echo "行数和列数必须为数字，请重新输入。"
    read -p "请输入水平方向上的小图数量: " num_cols
    read -p "请输入垂直方向上的小图数量: " num_rows
done

# 计算每张小图的宽度和高度
small_width=$((image_width / num_cols))
small_height=$((image_height / num_rows))

# 设置水平和垂直偏移初始值为 0
x_offset=0
y_offset=0

# 打印输入的参数
echo "输入的参数如下:"
echo "处理图路径: $input_file"
echo "输出图片目录: $output_dir"
echo "每张小图的宽度: $small_width"
echo "每张小图的高度: $small_height"
# echo "水平偏移初始值: $x_offset"
# echo "垂直偏移初始值: $y_offset"
echo "水平方向上的小图数量: $num_cols"
echo "垂直方向上的小图数量: $num_rows"

# 图片编号
image_num=1

# 遍历每个小图的裁切区域
for ((row=0; row<num_rows; row++)); do
    for ((col=0; col<num_cols; col++)); do
        # 计算当前小图的左上角坐标
        x=$(( col * small_width + x_offset))
        y=$(( row * small_height + y_offset))
        
        # 执行裁切命令
        magick "$input_file" -crop ${small_width}x${small_height}+${x}+${y} +repage "$output_dir/output_${image_num}.png"
        ((image_num++))
    done
done

echo "所有图片裁切完毕！"