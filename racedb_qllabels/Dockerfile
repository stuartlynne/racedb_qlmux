FROM esitarski/racedb:v3.0.98-20240320103427

# CSRF_TRUSTED_ORIGINS is set in docker.env via DOCKERBUILDARGS
ARG CSRF_TRUSTED_ORIGINS
ENV CSRF_TRUSTED_ORIGINS $CSRF_TRUSTED_ORIGINS
ENV TIME_ZONE=America/Vancouver

# Add ssh to allow ssh access to qlmux_proxy if that is preferred
RUN apk add --no-cache openssh-client ca-certificates bash make
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install --upgrade Pillow

# The pypi version of brother_ql is out of date, we will will install from github repo instead
# This eliminates an out of date message about deprecation.
RUN cd / && git clone https://github.com/pklaus/brother_ql.git
RUN cd /brother_ql && python3 setup.py install

# Install qllabels if that is preferred
RUN cd / && git clone https://github.com/stuartlynne/qllabels.git 
RUN cd /qllabels && make install 

# Append CSRF_TRUSTED_ORIGINS to RaceDB	Settings, 
# doing it in csrf.py to get the quoting right and support multiple URL's.
COPY csrf.py /csrf.py
RUN cd / && /csrf.py >> /RaceDB/RaceDB/settings.py


CMD ["/usr/sbin/entrypoint.sh"]
