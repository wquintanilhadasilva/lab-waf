# Imagem base
FROM nginx:latest as nginx-base

# Atualiza o sistema e instala as dependências necessárias
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    wget \
    libmodsecurity-dev \
    libpcre3-dev

FROM nginx-base as websecurity
# Baixa o código-fonte do ModSecurity
RUN wget https://github.com/SpiderLabs/ModSecurity/releases/download/v3.0.4/modsecurity-v3.0.4.tar.gz && \
    tar -xvf modsecurity-v3.0.4.tar.gz

# Compila e instala o ModSecurity
RUN cd modsecurity-v3.0.4 && \
    ./configure && \
    make && \
    make install

FROM websecurity as owasp
# Baixa o conjunto básico de regras do ModSecurity
RUN git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /usr/src/owasp-modsecurity-crs && \
    cd /usr/src/owasp-modsecurity-crs && \
    git checkout v3.3.2 && \
    mv crs-setup.conf.example crs-setup.conf

FROM owasp
# Copia o arquivo de configuração do Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Copia o arquivo de configuração do ModSecurity
COPY modsecurity.conf /etc/nginx/modsecurity/modsecurity.conf

# Configura o diretório para as regras do ModSecurity
RUN mkdir -p /etc/nginx/modsecurity.d && \
    echo "Include /usr/src/owasp-modsecurity-crs/crs-setup.conf" > /etc/nginx/modsecurity.d/owasp-modsecurity-crs-base.conf && \
    echo "Include /usr/src/owasp-modsecurity-crs/rules/*.conf" >> /etc/nginx/modsecurity.d/owasp-modsecurity-crs-base.conf

# Remove o código-fonte e outras dependências não mais necessárias
RUN rm -rf modsecurity-3.0.4 modsecurity-3.0.4.tar.gz && \
    apt-get purge -y build-essential wget && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Expõe a porta 80
EXPOSE 80

# Inicia o servidor Nginx
CMD ["nginx", "-g", "daemon off;"]
