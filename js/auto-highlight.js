[
  '//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.6/highlight.min.js',
].forEach(function(src) {
    var script = document.createElement('script');
    script.src = src;
    script.async = false;
    document.head.appendChild(script);
  });

function matchAny(data, filterParams){
    //data - the data for the row being filtered
    //filterParams - params object passed to the filter
    var match = false;
    for(var key in data){
        if(data[key].toLowerCase().indexOf(filterParams.value.toLowerCase()) > -1 ){
            match = true;
        }
    }
    return match;
}

function commonOrigin(url) {
  var pageLocation = window.location;
  var URL_HOST_PATTERN = /(\w+:)?(?:\/\/)([\w.-]+)?(?::(\d+))?\/?/;
  var urlMatch = URL_HOST_PATTERN.exec(url) || [];
  var urlparts = {
      protocol:   urlMatch[1] || '',
      host:       urlMatch[2] || '',
      port:       urlMatch[3] || ''
  };

  function defaultPort(protocol) {
     return {'http:':80, 'https:':443}[protocol];
  }

  function portOf(location) {
     return location.port || defaultPort(location.protocol||pageLocation.protocol);
  }

  return !!(  (urlparts.protocol  && (urlparts.protocol  == pageLocation.protocol)) &&
              (urlparts.host     && (urlparts.host      == pageLocation.host))     &&
              (urlparts.host     && (portOf(urlparts) == portOf(pageLocation)))
          );
}

function defer(){
  if ( window.hljs ){
    link = document.createElement('link');
    link.type = "text/css";
    link.rel = "stylesheet";
    link.href = '//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.6/styles/atelier-cave-light.min.css';
    document.head.appendChild(link);
    hljs.initHighlightingOnLoad();
  } else {
    window.setTimeout("defer();",100);
  }
}
defer();
