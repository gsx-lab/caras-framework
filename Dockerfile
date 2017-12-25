FROM ruby:2.4.3

ENV APPDIR="/caras-app/" \
    LANG="C.UTF-8"

WORKDIR ${APPDIR}

RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install apt-transport-https \
 && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
 && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
 && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
 && apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
   libmagic-dev \
   libreadline-dev \
   nmap \
   nodejs \
   postgresql-client \
   rsync \
   yarn \
 && apt-get clean \
 && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* \
 && printf "install: --no-document\nupdate: --no-document\n" >> ~/.gemrc \
 && gem install bundler \
 && bundle config build.nokogiri --use-system-libraries \
 && apt-get clean \
 && rm -rf /var/cache/apt-archive/* /var/lib/apt/lists/*

COPY ./ ${APPDIR}
RUN cp ${APPDIR}/containers/app/docker-entrypoint.sh /usr/local/bin \
 && chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bin/carash"]
