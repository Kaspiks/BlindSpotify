FROM postgres:12

RUN localedef \
  --inputfile en_US \
  --force \
  --charmap UTF-8 \
  --alias-file /usr/share/locale/locale.alias \
  en_US.UTF-8

ENV LANG='en_US.utf8'


