# This Dockerfile is used to build an headles vnc image based on Ubuntu

FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

LABEL io.k8s.description="Headless VNC Container with Xfce window manager, firefox and chromium" \
      io.k8s.display-name="Headless VNC Container based on Ubuntu" \
      io.openshift.expose-services="6901:http,5901:xvnc" \
      io.openshift.tags="vnc, ubuntu, xfce" \
      io.openshift.non-scalable=true

## Connection ports for controlling the UI :
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901
EXPOSE $VNC_PORT $NO_VNC_PORT

### Envrionment config
ENV HOME=/root \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    INST_SCRIPTS=/headless/install \
    NO_VNC_HOME=/headless/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false

WORKDIR $HOME

### Install Base utils
RUN apt-get update && \
    apt-get install -y net-tools locales bzip2 \
        build-essential ca-certificates cmake \
        curl git vim vim wget \
        openssh-server openssh-client \
        python-numpy \
        ttf-wqy-zenhei \
        chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg \
        supervisor xfce4 xfce4-terminal xterm \
        libnss-wrapper gettext

RUN apt-get purge -y pm-utils xscreensaver*
#        && \
#        apt-get clean -y && \
#        apt-get autoremove -y && \
#        rm -rf /var/lib/apt/lists/*

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-1.8.0.x86_64.tar.gz | tar xz --strip 1 -C / && \
    mkdir -p $NO_VNC_HOME/utils/websockify && \
    wget -qO- https://github.com/novnc/noVNC/archive/v1.0.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME && \
    # use older version of websockify to prevent hanging connections on offline containers, see https://github.com/ConSol/docker-headless-vnc-container/issues/50
    wget -qO- https://github.com/novnc/websockify/archive/v0.6.1.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME/utils/websockify && \
    chmod +x -v $NO_VNC_HOME/utils/*.sh && \
    ## create index.html to forward automatically to `vnc_lite.html`
    ln -s $NO_VNC_HOME/vnc_lite.html $NO_VNC_HOME/index.html

### install pycharm
RUN mkdir -p /opt/pycharm && \
    wget -qO- https://download.jetbrains.com/python/pycharm-community-2019.1.3.tar.gz | tar xz --strip 1 -C /opt/pycharm

### Install chrome browser
RUN ln -s /usr/bin/chromium-browser /usr/bin/google-chrome && \
    ### fix to start chromium in a Docker container, see https://github.com/ConSol/docker-headless-vnc-container/issues/2
    echo "CHROMIUM_FLAGS='--no-sandbox --start-maximized --user-data-dir'" > $HOME/.chromium-browser.init


### Install xfce UI
ADD xfce/ $HOME/

### install anaconda3
RUN curl -o /tmp/anaconda.sh https://mirrors.tuna.tsinghua.edu.cn/anaconda/archive/Anaconda3-5.2.0-Linux-x86_64.sh && \
    chmod +x /tmp/anaconda.sh && \
    bash /tmp/anaconda.sh -b -p /opt/anaconda3 && \
    rm /tmp/anaconda.sh && \
    echo 'export PATH="/opt/anaconda3/bin:$PATH"' >> ~/.bashrc

RUN /opt/anaconda3/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free && \
    /opt/anaconda3/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main && \
    /opt/anaconda3/bin/conda config --set show_channel_urls yes && \

    # pip install tensorflow-gpu:lastest, torch and others
    /opt/anaconda3/bin/conda install -y tensorflow-gpu==1.13.1 && \
    /opt/anaconda3/bin/conda clean -y --all && \
    rm -rf ~/.cache/pip/*

### configure startup
ADD scripts $STARTUPDIR
RUN chmod a+x $STARTUPDIR/set_user_permission.sh && \
    $STARTUPDIR/set_user_permission.sh $STARTUPDIR $HOME

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--wait"]