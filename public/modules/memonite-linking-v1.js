console.log('linking module loaded');

(() => {
  const { loadScript, loadCss, initResourceEditor, isUrl } = Memonite;
  const linking = Memonite.linking = {
    followLink,
    getLinkPropertiesForInsertion,
  };

  window.onpopstate = onPopState

  function followLink(link, opts = {}) {
    if (opts.ifNewResource) {
      if (isUrl(link.href)) return;
      createResourceNX(link.href, link.label).then((resource) => {
        if (resource) {
          followLink(link, _.omit(opts, 'ifNewResource'))
        }
        return;
      });
      return;
    }
    if (!Memonite.spa) {
      console.warn('spa not defined => followLink reverting to page load')
      location.href = link.href;
      return;
    }
    const stateObj = { };
    console.log('pushState', stateObj, link.href, link)
    history.pushState(stateObj, '', link.href);
    replaceResourceByCurrentLocation()
  }

  function replaceResourceByCurrentLocation() {
    // Load resource from the backend // TODO: or cache
    $.ajax({
      url: location.href + '.json',
      method: 'get',
      dataType: 'json',
      success: (resource) => {
        resource.url = location.href
        console.log('backend returned', resource)
        Memonite.spa.showResource(resource)
      }
    })
  }

  function onPopState(stateObj) {
    console.log('popState', stateObj)
    if (!Memonite.spa) {
      console.warn('spa not defined => onPopState reverting to page load')
      location.href = location.href;
      return;
    }
    replaceResourceByCurrentLocation();
  }

  function getLinkPropertiesForInsertion() {
    return new Promise((resolve, reject) => {
      var label;
      Memonite.ui.prompt('Link label:').then((label) => {
        if (!label || label === '') return;

        const defaultHref = `/${label.toLowerCase().replace(/[^a-z0-9-]/g, '-')}`
        // const defaultHref = `${Math.random().toString(36).substring(2)}`
        Memonite.ui.prompt('Target URL or href', defaultHref).then((href) => {
          resolve({
            label: label,
            href: href,
          })
        })
      })
    })
  }

  function createResourceNX(href, title) {
    return new Promise((resolve, reject) => {
      $.ajax({
        method: 'post',
        url: href + '.json',
        data: { title: title, authenticity_token: authenticityToken },
        dataType: 'json',
        success: (resource) => {
          resolve(resource);
        },
        error: (err) => {
          // console.error('$.ajax error', err);
          logError({
            error: 'Could not create new resource',
            params: { href, title },
            reason: '$.ajax error',
            original: err
          }, reject)
        }
      })
    })
  }

  function logError(err, reject) {
    console.error(err.error, err.params, err.reason, err.original);
    if (reject) reject(err);
  }
})()
