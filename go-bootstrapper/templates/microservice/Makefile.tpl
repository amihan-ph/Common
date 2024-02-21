DOCKER_REGISTRY=harbor.amihan.net/{{ .ProjectGroup }}
APP={{ .ProjectSlug }}
TAG=latest
IMAGE=${DOCKER_REGISTRY}/${APP}:${TAG}
HARBOR_REGISTRY=harbor.amihan.net
PROJECT=amihan
CHART_REPO=harbor.amihan.net/chartrepo
CHARTDIR={{ .ProjectSlug }}

all: clean lint build test package

clean:
	@echo '========================================'
	@echo ' Cleaning project'
	@echo '========================================'
	@go clean
	@rm -rf build | true
	@docker-compose down
	@echo 'Done.'

deps:
	@echo '========================================'
	@echo ' Getting Dependencies'
	@echo '========================================'
	@echo 'Cleaning up dependency list...'
	@go mod tidy
	@echo 'Vendoring dependencies...'
	go mod vendor

gen:
	@echo '========================================'
	@echo ' Generating dependencies'
	@echo '========================================'
	@go generate ./cmd

build: deps gen
	@echo '========================================'
	@echo ' Building project'
	@echo '========================================'
	go fmt ./...
	@go build -mod=vendor -o build/bin/${APP} -ldflags "-X main.version=${TAG} -w -s" .
	@echo 'Done.'

test:
	@echo '========================================'
	@echo ' Running tests'
	@echo '========================================'
	@go test ./...
	@echo 'Done.'

lint:
	@echo '========================================'
	@echo ' Running lint'
	@echo '========================================'
	@golint ./...
	@echo 'Done.'

run-deps:
	@echo '========================================'
	@echo ' Running dependencies'
	@echo '========================================'
	@docker-compose up -d

{{- if .HasDB}}migrate:
	@echo '========================================'
	@echo ' Running migrations'
	@echo '========================================'
	@build/bin/${APP} migrate ${ARGS}{{end -}}


run: build
	@echo '========================================'
	@echo ' Running application'
	@echo '========================================'

	@build/bin/${APP} serve ${ARGS}
	@echo 'Done.'

package-image:
	@echo '========================================'
	@echo ' Packaging docker image'
	@echo '========================================'
	docker build -t ${IMAGE} .
	@echo 'Done.'

package-chart:
	@echo '========================================'
	@echo ' Packaging chart'
	@echo '========================================'
	@rm -r build/chart || true
	@mkdir -p build/chart/${APP}/files
	@cp -r helm/${APP} build/chart
	@cp config/rbac.yaml build/chart/${APP}/files/
	@helm package -u -d build/chart build/chart/${APP}
	@echo 'Done.'

package: package-image

publish-image: package-image
	@echo '========================================'
	@echo ' Publishing image'
	@echo '========================================'
	docker push ${IMAGE}
	@echo 'Done.'

publish-chart: package-chart
	@echo '========================================'
	@echo ' Publishing chart'
	@echo '========================================'
	helm push build/chart/${APP} ${PROJECT}
	@echo 'Done.'

publish: publish-image publish-chart

start:
	@echo '========================================'
	@echo ' Starting application'
	@echo '========================================'
	go run . serve
	@echo 'Done.'

devops-harbor-login:
	echo ${HARBOR_PASS} | docker login ${HARBOR_REGISTRY} --username ${HARBOR_USER} --password-stdin


devops-setup-helm:
	helm repo add ${PROJECT} https://${CHART_REPO}/${PROJECT} --username ${HARBOR_USER} --password ${HARBOR_PASS} 
	helm repo update

devops-deploy-chart:
	helm upgrade ${APP} --install \
		--namespace ${NAMESPACE} \
		--set image.tag=${TAG} \
		--set registries[0].url=${HARBOR_REGISTRY} \
		--set registries[0].username=${HARBOR_USER} \
		--set registries[0].password=${HARBOR_PASS} \
		--set createSecrets=${CREATE_SECRETS} \
		--set secrets.aes-key=${SKIP32_KEY} \
		--set secrets.s3-access-key=${AES_KEY} \
		--set secrets.s3-secret-key=${S3_ACCESS_KEY} \
        --set secrets.skip32-key=${S3_SECRET_KEY} \
		--set secrets.db-username=${DB_USERNAME} \
        --set secrets.db-password=${DB_USERNAME} \
		--set config.s3.endpoint=${S3_URL} \
		--set config.kafka.brokers[0]=${KAFKA_BROKERS} \
		--set extraLabels.git_hash=\"${CI_COMMIT_SHORT_SHA}\" \
		--set extraLabels.app=${CI_ENVIRONMENT_SLUG} \
		--values ${VALUES_FILE} helm/${CHARTDIR}
