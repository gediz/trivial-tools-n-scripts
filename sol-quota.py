from bs4 import BeautifulSoup
from requests import Session

LoginCredentials = {
    'customerNo': 'superonline-HESABIM-kullanici-adi',
    'password': 'superonline-HESABIM-parola'
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

    # Unrecognizable mess
    TableData = QuotaPage_Parsed.find(class_='bb').find_all('td')
    DownloadAmount = ' '.join(TableData[1].text.split())
    UploadAmount = ' '.join(TableData[2].text.split())

    print('Download: {}\nUpload: {}'.format(DownloadAmount, UploadAmount))
