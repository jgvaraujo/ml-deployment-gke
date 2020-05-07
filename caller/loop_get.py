import requests, time, datetime

i = 0
kind = 'local'
while True:
    ans = input('This is a local test? [Y/n] ')
    print()
    if ans in ('y', 'Y', ''):
        url = 'http://localhost:8080/'
        print('Application address (http://example:8080/):', url)
        break
    elif ans in ('n', 'N'):
        url = ''
        kind = 'cloud'
        while url == '':
            url = input('Put the application address (https://example:8080/): ')
        if url[-1] != '/':
            url = url + '/'
        if url[:8] != 'https://' and url [:7] != 'http://':
            url = 'http://' + url
        print('Application URL:', url)
        break

print()

i = 1
t = datetime.timedelta(0)
errors = 0
if kind == 'local':
    mv = 50
else:
    mv = 10
while True:
    try:
        r = requests.get(url)
        t += r.elapsed

        if i%mv==0:
            print(i, t/mv, r.text, 'errors:%d' % errors, end='\r')
            t = datetime.timedelta(0)

        i += 1
    except KeyboardInterrupt:
        print('\n[!] KeyboardInterrupt')
        break
    except:
        print('\nERROR!')
        errors += 1