FROM jupyter/base-notebook:latest

USER root
RUN wget https://julialang-s3.julialang.org/bin/linux/x64/1.7/julia-1.7.3-linux-x86_64.tar.gz && \
    tar -xvzf julia-1.7.3-linux-x86_64.tar.gz && \
    mv julia-1.7.3 /opt/ && \
    ln -s /opt/julia-1.7.3/bin/julia /usr/local/bin/julia && \
    rm julia-1.7.3-linux-x86_64.tar.gz

USER ${NB_USER}

COPY --chown=${NB_USER}:users ./plutoserver ./plutoserver
COPY --chown=${NB_USER}:users ./environment.yml ./environment.yml
COPY --chown=${NB_USER}:users ./setup.py ./setup.py
COPY --chown=${NB_USER}:users ./runpluto.sh ./runpluto.sh
COPY --chown=${NB_USER}:users ./Project.toml ./Project.toml
COPY --chown=${NB_USER}:users ./Manifest.toml ./Manifest.toml

COPY --chown=${NB_USER}:users ./combined_trace.jl ./combined_trace.jl
COPY --chown=${NB_USER}:users ./create_sysimage.jl ./create_sysimage.jl

ENV USER_HOME_DIR /home/${NB_USER}
ENV JULIA_PROJECT ${USER_HOME_DIR}
ENV JULIA_DEPOT_PATH ${USER_HOME_DIR}/.julia
WORKDIR ${USER_HOME_DIR}

RUN julia -e "import Pkg; Pkg.Registry.update(); Pkg.instantiate();"

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
        apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_USER}

RUN julia --project=${USER_HOME_DIR} create_sysimage.jl
RUN julia -J${USER_HOME_DIR}/sysimage.so --project=${USER_HOME_DIR} -e "using Pluto"

RUN jupyter labextension install @jupyterlab/server-proxy && \
    jupyter lab build && \
    jupyter lab clean && \
    pip install . --no-cache-dir && \
    rm -rf ~/.cache
