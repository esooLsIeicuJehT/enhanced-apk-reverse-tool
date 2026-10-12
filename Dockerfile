# Production image for the APK analysis API.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG APKTOOL_VERSION=2.8.1

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    DATA_DIR=/data \
    APP_ENV=production
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
        adb \
        aapt \
        apksigner \
        ca-certificates \
        curl \
        file \
        jq \
        openjdk-17-jre-headless \
        python3 \
        python3-pip \
        python3-venv \
        unzip \
        wget \
        zip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv "$VIRTUAL_ENV" \
    && "$VIRTUAL_ENV/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN "$VIRTUAL_ENV/bin/pip" install --no-cache-dir -r /app/requirements.txt

RUN wget -q "https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VERSION}/apktool_${APKTOOL_VERSION}.jar" -O /opt/apktool.jar \
    && printf '#!/usr/bin/env sh\nexec java -jar /opt/apktool.jar "$@"\n' > /usr/local/bin/apktool \
    && chmod 0755 /usr/local/bin/apktool

COPY . /app

RUN chmod 0755 /app/apk-reverse-tool.sh /app/integrate.sh \
    && useradd --create-home --uid 10001 --shell /usr/sbin/nologin apktool \
    && mkdir -p /data/uploads /data/results /data/work \
    && chown -R apktool:apktool /app /data

USER apktool

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl --fail --silent http://127.0.0.1:8080/api/health >/dev/null || exit 1

CMD ["gunicorn", "--chdir", "api-server", "--workers", "1", "--threads", "8", "--bind", "0.0.0.0:8080", "--timeout", "120", "--access-logfile", "-", "--error-logfile", "-", "wsgi:app"]
