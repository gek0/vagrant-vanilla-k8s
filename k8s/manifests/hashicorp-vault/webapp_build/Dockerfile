FROM python:3.12.0
LABEL name="mburisa-vault-webapp-example"
LABEL maintainer="Matija Buriša <matijaburisa@gmail.com>"

COPY app.py requirements.txt ./

RUN pip install -r requirements.txt

EXPOSE 8000
CMD ["python", "app.py"]