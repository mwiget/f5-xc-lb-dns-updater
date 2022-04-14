all: blindfold build push

build:
	docker build -t lb-dns-updater .

blindfold:
	./blindfold.sh

push:
	docker tag lb-dns-updater:latest marcelwiget/lb-dns-updater:latest
	docker push marcelwiget/lb-dns-updater:latest	
