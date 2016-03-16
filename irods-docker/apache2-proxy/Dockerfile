FROM httpd:2

MAINTAINER Mike Knowles <mikewknowles+rods@gmail.com>

RUN mkdir sites-enabled/
ADD ./ajp.apache sites-available/ajp.apache.conf
#RUN a2enmod proxy_ajp
RUN sed -e 's/#LoadModule proxy_ajp_module/LoadModule proxy_ajp_module/' -i conf/httpd.conf
RUN sed -e 's/#LoadModule proxy_module/LoadModule proxy_module/' -i conf/httpd.conf
RUN echo "Include sites-enabled" conf/httpd.conf && \
    echo "IncludeOptional sites-enabled/*.conf" conf/httpd.conf && \
    cat sites-available/ajp.apache.conf >> conf/httpd.conf
RUN ln -s /export/etc/irods/chain.pem /usr/local/apache2/conf/server.crt
RUN ln -s /export/etc/irods/server.key /usr/local/apache2/conf/server.key

ADD ./entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
CMD ["/docker-entrypoint.sh"]

EXPOSE 443