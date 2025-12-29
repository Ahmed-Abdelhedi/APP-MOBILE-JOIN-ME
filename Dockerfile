# Flutter Mobile App - Docker Image
# Ensures consistent Flutter, Java, Gradle, and Android SDK across all PCs

# Use official Flutter image with Android SDK pre-installed
FROM ghcr.io/cirruslabs/flutter:stable

# Set environment variables
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

# Install required dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set Java 17 as default
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Create app directory
WORKDIR /app

# Copy the entire project
COPY . .

# Accept Android SDK licenses
RUN yes | flutter doctor --android-licenses || true

# Get Flutter dependencies
RUN flutter pub get

# Pre-download Gradle dependencies to speed up subsequent builds
RUN cd android && ./gradlew --version || true

# Build the APK (this validates the setup and caches dependencies)
RUN flutter build apk --debug || echo "Initial build attempted, continuing..."

# Expose ADB port for device connection
EXPOSE 5037

# Default command shows Flutter doctor
CMD ["flutter", "doctor", "-v"]
