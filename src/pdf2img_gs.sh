#!/bin/bash

# 检测 Ghostscript 是否安装
if ! command -v gs &> /dev/null; then
    echo "Ghostscript 未安装，请先安装 Ghostscript。"
    exit 1
fi

# 检测 pdfinfo 是否安装
if ! command -v pdfinfo &> /dev/null; then
    echo "pdfinfo 未安装，请先安装 Poppler 工具集。"
    exit 1
fi

# 手动输入参数
read -p "请输入输入PDF文件路径 (默认: 当前路径/input.pdf): " input_pdf

# 如果输入PDF文件路径为空，遍历当前文件夹下的PDF文件并提供选择
if [ -z "$input_pdf" ]; then
    pdf_files=(*.pdf)
    if [ ${#pdf_files[@]} -eq 0 ]; then
        echo "当前文件夹下没有找到任何PDF文件。"
        exit 1
    fi

    echo "当前文件夹下的PDF文件列表:"
    for i in "${!pdf_files[@]}"; do
        echo "$((i+1)). ${pdf_files[i]}"
    done

    read -p "请选择一个PDF文件 (输入数字): " choice

    # 校验用户输入是否为有效的数字
    while ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -le 0 ] || [ "$choice" -gt "${#pdf_files[@]}" ]; do
        read -p "无效的选择，请重新输入一个数字: " choice
    done

    input_pdf="${pdf_files[$((choice-1))]}"
else
    # 如果用户输入了路径，检查文件是否存在
    if [ ! -f "$input_pdf" ]; then
        echo "文件 $input_pdf 不存在。"
        exit 1
    fi
fi

read -p "请输入输出图片目录 (默认: 当前路径/output_images): " output_dir
read -p "请输入输出图片格式 (默认: png): " output_format
read -p "请输入密度 (默认: 300): " density
read -p "请输入缩放倍数 (默认: 1.0, 范围: 0.01-100): " resize_factor

# 设置默认值
output_dir=${output_dir:-"output_images"}
output_format=${output_format:-"png"}
density=${density:-"300"}
resize_factor=${resize_factor:-"1.0"}

# 校验函数
validate_number() {
    local value="$1"
    local prompt="$2"
    while ! [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]]; do
        read -p "$prompt" value
    done
    echo "$value"
}

# 校验并设置参数
density=$(validate_number "$density" "请输入密度 (默认: 300): ")
resize_factor=$(validate_number "$resize_factor" "请输入缩放倍数 (默认: 1.0, 范围: 0.01-100): ")

# 校验 resize_factor 是否在 0.01 到 100 之间
while (( $(echo "$resize_factor < 0.01" | bc -l) )) || (( $(echo "$resize_factor > 100" | bc -l) )); do
    read -p "缩放倍数必须在 0.01 到 100 之间，请重新输入: " resize_factor
    resize_factor=$(validate_number "$resize_factor" "请输入缩放倍数 (默认: 1.0, 范围: 0.01-100): ")
done

# 打印输入的参数
echo "输入的参数如下:"
echo "输入PDF文件路径: $input_pdf"
echo "输出图片目录: $output_dir"
echo "输出图片格式: $output_format"
echo "密度: $density"
echo "缩放倍数: $resize_factor"

# 创建输出目录，如果不存在
mkdir -p "$output_dir"

# 计算缩放因子
resize_value=$(echo "$resize_factor * 100" | bc)

# 设置正确的 Ghostscript 设备
if [ "$output_format" == "png" ]; then
    gs_device="png16m"
else
    gs_device="$output_format"
fi

# 获取 PDF 文件的总页数
total_pages=$(pdfinfo "$input_pdf" | grep "Pages:" | awk '{print $2}')
if [ -z "$total_pages" ]; then
    echo "无法获取 PDF 文件的总页数。"
    exit 1
fi

# 构建 Ghostscript 命令
gs_command="gs -dBATCH -dNOPAUSE -sDEVICE=$gs_device -r$density -dFirstPage=1 -dLastPage=$total_pages -dFIXEDMEDIA -dPDFFitPage -dUseCropBox -dAutoRotatePages=/None -dGraphicsAlphaBits=4 -dTextAlphaBits=4 -dEPSCrop -sOutputFile=\"$output_dir/output_%03d.$output_format\" \"$input_pdf\""

# 打印要执行的命令
echo "要执行的命令: $gs_command"

# 使用 Ghostscript 的 gs 命令将 PDF 转换为图片
eval "$gs_command"

echo "PDF 转换为图片完成！"