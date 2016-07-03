FROM gliderlabs/alpine

MAINTAINER blacktop, https://github.com/blacktop

ENV KIBANA 4.5
ENV ELASTIC 2.3.3
ENV LOGSTASH 2.3
ENV GOSU_VERSION 1.7
ENV GOSU_URL https://github.com/tianon/gosu/releases/download

# Grab gosu for easy step-down from root
RUN apk-install -t build-deps wget ca-certificates gpgme \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
  && apk del --purge build-deps

RUN apk-install openjdk8-jre
RUN apk-install -t build-deps wget ca-certificates \
  && cd /tmp \
  && wget -O elasticsearch-$ELASTIC.tar.gz https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$ELASTIC/elasticsearch-$ELASTIC.tar.gz \
  && tar -xzf elasticsearch-$ELASTIC.tar.gz \
  && mv elasticsearch-$ELASTIC /usr/share/elasticsearch \
  && adduser -DH -s /sbin/nologin elasticsearch \
	&& echo "Creating Elasticsearch Paths..." \
	&& for path in \
		/usr/share/elasticsearch/data \
		/usr/share/elasticsearch/logs \
		/usr/share/elasticsearch/config \
		/usr/share/elasticsearch/config/scripts \
		/usr/share/elasticsearch/plugins \
	; do \
	mkdir -p "$path"; \
	done \
  && chown -R elasticsearch:elasticsearch /usr/share/elasticsearch \
  && rm -rf /tmp/* \
  && apk del --purge build-deps

COPY config/elastic /usr/share/elasticsearch/config
COPY entrypoints/elastic-entrypoint.sh /
RUN chmod +x /elastic-entrypoint.sh

VOLUME ["/usr/share/elasticsearch/data"]
EXPOSE 9200 9300

ENV PATH /usr/share/elasticsearch/bin:$PATH

ENTRYPOINT ["/elastic-entrypoint.sh"]

CMD ["elasticsearch"]
