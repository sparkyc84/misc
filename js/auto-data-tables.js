/*  Auto-Data-Tables 
/*  This script will inject searchable data tables into a web page using Tabulator
/*  It currently requires Bootstrap stylesheets from <https://getbootstrap.com/>,
/*  To use on non- Bootstrap sites you could either inject Boostrap styles or amend the stylesheet.
*/
[
  '/static/js/papaparse/papaparse.min.js',
  '/static/js/tabulator/dist/js/tabulator.min.js',
  '//oss.sheetjs.com/js-xlsx/xlsx.full.min.js',
].forEach(function(src) {
    var script = document.createElement('script');
    script.src = src;
    script.async = false;
    document.head.appendChild(script);
  });

function matchAny(data, filterParams){
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
  if ( window.Tabulator && window.Papa ){
    link = document.createElement('link');
    link.type = "text/css";
    link.rel = "stylesheet";
    link.href = '/static/js/tabulator/dist/css/tabulator.min.css';
    document.head.appendChild(link);
    document.querySelectorAll('a[href$="csv"]').forEach(function(csv, i) {
      if (!commonOrigin(csv.href))
        return false;
      Papa.parse(csv.getAttribute('href'), { download: true, header: true, complete: function(results) {
        var tableId = 'data-table-'+i;
        csv.insertAdjacentHTML('beforebegin','<nav class="navbar navbar-expand-lg navbar-light"  data-controls="#'+tableId+'" style="background-color: #e3f2fd;"><a class="navbar-brand" href="'+csv.href+'">'+csv.text+'</a>  <button class="btn btn-success ml-auto" data-action="load-table">Explore Data</button></nav><div id="'+tableId+'" class="my-2"></div>');
        csv.parentNode.removeChild(csv);
        document.querySelector('[data-controls="#'+tableId+'"] [data-action="load-table"]').addEventListener( 'click', function (e){
        e.target.setAttribute('disabled',true);
        e.target.insertAdjacentHTML('beforeend', ' <div id="loading-spinner-'+tableId+'" class="spinner-border text-light" role="status"> <span class="sr-only">Loading...</span> </div>');
        e.target.insertAdjacentHTML('afterend','<div id="navbar-'+tableId+'" class="collapse navbar-collapse" id="navbar-'+tableId+'"><form class="form-inline table-controls  my-2 my-lg-0"><label for="table-filter-'+tableId+'" class="mr-2">Filter </label> <input type="text" class="form-control form-control-sm" id="table-filter-'+tableId+'" placeholder="Search in entire table" data-action="form-filter"></form><ul class="ml-auto navbar-nav"><li class="nav-item dropdown" role="group"> <a id="navbar-dropdown-'+tableId+'" role="button" class="nav-link dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Download</button><div class="dropdown-menu" aria-labelledby="navbar-dropdown-'+tableId+'"> <a class="dropdown-item" data-action="download-excel" href="#">Excel Spreadsheet</a> <a href="#" class="dropdown-item" data-action="download-csv">Comma Separated Values (CSV)</a></div></li></ul></div>');
        e.target.insertAdjacentHTML('beforebegin','<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbar-'+tableId+'" aria-controls="navbar-'+tableId+'" aria-expanded="false" aria-label="Toggle navigation"> <span class="navbar-toggler-icon"></span> </button>');
        e.target.parentNode.removeChild(e.target);
        var table = new Tabulator('#'+tableId,{data: results.data, autoColumns: true, height: '30em', responsiveLayout: 'hide', tableBuilt: function(){
          console.log(tableId);
          document.querySelector('[data-controls="#'+tableId+'"] [data-action="form-filter"]').addEventListener( 'keyup', function (e){
            table.setFilter(matchAny, { value: this.value });
            if ( this.value == " "){
              table.clearFilter();
            }
          }, false);
          document.querySelector('[data-controls="#'+tableId+'"] [data-action="download-excel"]').addEventListener( 'click', function (e){
            table.download("xlsx", "table-data.xlsx", {sheetName:"MyData"});
            e.preventDefault();
          }, false);
          document.querySelector('[data-controls="#'+tableId+'"] [data-action="download-csv"]').addEventListener( 'click', function (e){
            table.download("csv", "table-data.csv", {bom:true});
            e.preventDefault();
          }, false);
        }});
        console.log(e.target);
        e.preventDefault();
        }, false);
      }
      });
    });
  } else {
    window.setTimeout("defer();",100);
  }
}
defer();
