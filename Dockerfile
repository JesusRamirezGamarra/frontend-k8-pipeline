#etapa de nginx
FROM nginx:alpine

#copiar el contenikdo del build de angular
COPY build/ /usr/share/nginx/html

#para exponer el puerto 80 del container
EXPOSE 80

#comando por defecto de nginx
CMD [ "nginx", "-g", "daemon off;" ]