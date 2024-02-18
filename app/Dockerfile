###################
# BUILD FOR PRODUCTION
###################

FROM node:16-alpine As build

COPY . /
WORKDIR /

RUN yarn

RUN yarn start
