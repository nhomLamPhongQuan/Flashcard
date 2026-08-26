# 1. Tải image có sẵn chứa Flutter SDK (bản 3.22.0) do Cirrus CI xây dựng
FROM ghcr.io/cirrusci/flutter:3.22.0

# 2. Cài đặt các công cụ bổ sung cần thiết cho hệ điều hành Linux trong container
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# 3. Chuyển quyền thao tác sang người dùng root
USER root