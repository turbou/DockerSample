import os
import json
import html
import requests
import csv
import argparse
from datetime import datetime as dt

def main():
    parser = argparse.ArgumentParser(
        prog='puttag4applications.py', # プログラム名
        usage='Demonstration of argparser', # プログラムの利用方法
        description='description', # 引数のヘルプの前に表示
        epilog='end', # 引数のヘルプの後で表示
        add_help=True, # -h/–help オプションの追加
    )
    parser.add_argument('--app', help='アプリケーションID(このアプリケーションにだけタグを付けます。動作確認用)')
    parser.add_argument('--tag-prefix', help='タグPrefix')
    args = parser.parse_args()

    env_not_found = False
    for env_key in ['CONTRAST_BASEURL', 'CONTRAST_AUTHORIZATION', 'CONTRAST_API_KEY', 'CONTRAST_ORG_ID']:
        if not env_key in os.environ:
            print('Environment variable %s is not set' % env_key)
            env_not_found |= True
    if env_not_found:
        print()
        print('CONTRAST_BASEURL                   : https://eval.contrastsecurity.com/Contrast')
        print('CONTRAST_AUTHORIZATION             : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==')
        print('CONTRAST_API_KEY                   : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
        print('CONTRAST_ORG_ID                    : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')
        print()
        return

    BASEURL=os.environ['CONTRAST_BASEURL']
    API_KEY=os.environ['CONTRAST_API_KEY']
    AUTHORIZATION=os.environ['CONTRAST_AUTHORIZATION']
    ORG_ID=os.environ['CONTRAST_ORG_ID']
    headers = {"Accept": "application/json", "content-type": "application/json", "API-Key": API_KEY, "Authorization": AUTHORIZATION}
    API_URL="%s/api/ng/%s" % (BASEURL, ORG_ID)

    APP_ID = None
    if args.app:
        APP_ID = args.app

    if args.tag_prefix is None:
        TAG_PREFIX = "original-name:"
    else:
        TAG_PREFIX = args.tag_prefix

    # =============== アプリケーション一覧を取得 ===============
    print('Application Loading...')
    all_applications = []
    url_applications = '%s/applications/filter?offset=%d&limit=25&expand=skip_links&sort=appName' % (API_URL, len(all_applications))
    r = requests.get(url_applications, headers=headers)
    data = r.json()
    totalCnt = data['count']
    for app in data['applications']:
        #print(app['app_id'])
        all_applications.append({'app_id': app['app_id'], 'name': app['name']})

    appsIncompleteFlg = True
    appsIncompleteFlg = totalCnt > len(all_applications)
    while appsIncompleteFlg:
        url_applications = '%s/applications/filter?offset=%d&limit=25&expand=skip_links&sort=appName' % (API_URL, len(all_applications))
        r = requests.get(url_applications, headers=headers)
        data = r.json()
        for app in data['applications']:
            #print(app['app_id'])
            all_applications.append({'app_id': app['app_id'], 'name': app['name']})
        appsIncompleteFlg = totalCnt > len(all_applications)
    print('Total(Applications): ', len(all_applications))

    while True:
        user_input = input("Do you want to continue? (yes/no): ")
        if user_input.lower() in ["yes", "y"]:
            print("Continuing...")
            break
        elif user_input.lower() in ["no", "n"]:
            print("Exiting...")
            return
        else:
            print("Invalid input. Please enter yes/no.")

    # =============== 最後にアプリケーションに対してタグを設定 ===============
    for app_info in all_applications:
        if APP_ID:
            if app_info['app_id'] != APP_ID:
                continue
        app_id = app_info['app_id']
        app_name = app_info['name']
        #print('%s(%s)' % (app_id, app_name))
        url_apps_put_tag = '%s/tags/applications/bulk?expand=skip_links' % (API_URL)
        tag_str = '%s%s' % (TAG_PREFIX, app_name)
        payload = '{"applications_id":["%s"],"tags":["%s"],"tags_remove":[]}' % (app_id, tag_str)
        r = requests.put(url_apps_put_tag, headers=headers, data=payload)
        data = r.json()
        print('%s: %s (%s)' % (app_id, data['success'], app_name))

if __name__ == '__main__':
    main()

