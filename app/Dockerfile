###################
# BUILD FOR PRODUCTION
###################

FROM node:20-alpine As build

COPY . /
WORKDIR /

RUN yarn

RUN yarn start
