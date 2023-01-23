FROM node:18
RUN git clone https://github.com/juice-shop/juice-shop.git --depth 1 /juice-shop
WORKDIR /juice-shop
RUN npm install
RUN npm install @contrast/agent --no-optional
COPY contrast_security.yaml .
CMD ["node", "-r", "@contrast/agent", "build/app.js"]
