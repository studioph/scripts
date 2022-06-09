const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

async function addProxy(item) {
    proxyName = item.textContent
    proxyNum = proxyName.split(' ')[1]
    proxyString = `socks://10.124.${proxyNum.replace('-','.')}:1080`

    item.click()
    proxySettingsButton = $('#advanced-proxy-settings-btn')
    proxySettingsButton.click()
    proxyTextInput = $('#edit-advanced-proxy-input')
    proxyTextInput.value = proxyString
    submitButton = $('#submit-advanced-proxy')
    submitButton.click()

    await sleep(100)

    backButton = $('#close-container-edit-panel')
    backButton.click()
}

async function addProxies() {
    proxyList = $$('#picker-identities-list tr span.menu-text');
    for (const item of proxyList) {
        await addProxy(item)
        await sleep(100)
    }
}
