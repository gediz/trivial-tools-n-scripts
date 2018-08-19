from datetime import datetime
from bs4 import BeautifulSoup
from requests import Session

LoginCredentials = {
    'customerNo': 'id',
    'password': 'pw'
}

Headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:61.0) Gecko/20100101 Firefox/61.0',
}

URL_Login = 'https://www.superonline.net/hesabim/giris'
URL_Quota = 'https://www.superonline.net/hesabim/internet-islemleri/guncel-kota-bilgisi'

with Session() as Superonline:
    Login = Superonline.post(URL_Login, data=LoginCredentials, headers=Headers)
    QuotaPage = Superonline.get(URL_Quota, headers=Headers)

    QuotaPage_Parsed = BeautifulSoup(QuotaPage.text, 'html.parser')

    # Unrecognizable mess, huh?
    DownloadAmount = ' '.join(QuotaPage_Parsed.find(class_='bb').find_all('td')[1].text.split())
    UploadAmount = ' '.join(QuotaPage_Parsed.find(class_='bb').find_all('td')[2].text.split())

    print('DL: {}\nUL: {}'.format(DownloadAmount, UploadAmount))
