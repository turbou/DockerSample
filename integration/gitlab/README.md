mkdir -p /srv/gitlab
mkdir -p /srv/gitlab-runner

998:998

##### gitlab-runnerの登録

gitlab-runnerコンテナの中にはいって

```sh
docker exec -it contrast_gitlab_demo.gitlab-runner bash
gitlab-runner register -n \
--url http://gitlab/ \
--registration-token ${TOKEN} \
--executor shell \
--description "contrast-runner"
```

トークンはGitlabの管理者エリア→概要→Runner の右上から確認できます。
表示されているURLは外部から接続する際の情報になっているので、コンテナ間通信の場合は異なるので注意してください。基本上記のコマンドのURLでよいです。

