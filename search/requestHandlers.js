var url = require("url")
var querystring = require("querystring")
var elasticsearch = require("elasticsearch")
var ejs = require("ejs")
var json = require("JSON")
var fs = require("fs")


function start(response)
{
    fs.readFile( "templates/index.html", "utf8", function(e,data) {
        response.writeHead(200, {"Content-Type": "text/html; charset=utf-8"})
        response.write(data)
        response.end()
    } )
}

function autocomplete(response, request)
{
    var query = querystring.parse( url.parse( request.url ).query ).q
    var index = url.parse( request.url ).pathname.split('/').slice(-2,-1)[0] || "default"
    var client = new elasticsearch.Client( {
        host: 'localhost:9200',
        //log: 'trace'
    } )
    client.search( {
        index: index,
        body: {
            from: 0,
            size: 10,
            query: {
                query_string: {
                    query: query,
                    fields: ["inurl^100","intitle^50","intext^5"],
                    default_operator: "AND",
                    fuzziness: "AUTO",
                    analyzer: "autocomplete"
                }
            },
            highlight: {
                order: "score",
                fields: {
                    "*": {
                        pre_tags: [""],
                        post_tags: [""],
                        fragment_size: 25,
                        number_of_fragments: 1
                    }
                }
            }
        }
    } )
    .then( function(res) {
        var found = res.hits.total
        matches = []
        for( var i = 0; i < res.hits.hits.length; i++ )
            for( item in res.hits.hits[i].highlight )
                matches.push( res.hits.hits[i].highlight[item][0] )
        response.writeHead(200, {"Content-Type": "text/json"})
        response.end( json.stringify(matches) )
    } )
}

function cache(response, request)
{
    var id = querystring.parse( url.parse( request.url ).query ).id
    var index = url.parse( request.url ).pathname.split('/').slice(-2,-1)[0] || "default"
    var client = new elasticsearch.Client( {
        host: 'localhost:9200',
        //log: 'trace'
    } )
    client.get( {
          index: index,
          type: 'page',
          id: id
        }, function (err, res) {
            response.writeHead(200, {"Content-Type": "text/html; charset=utf-8"})
            response.end( res._source.intext )
    } )
}

function search(response, request)
{
    var query = querystring.parse( url.parse( request.url ).query ).q
    var offset = parseInt( querystring.parse( url.parse( request.url ).query ).o ) || 1
    var index = url.parse( request.url ).pathname.split('/').slice(-2,-1)[0] || "default"
    var client = new elasticsearch.Client( {
        host: 'localhost:9200',
        //log: 'trace'
    } )
    client.search( {
        index: index,
        body: {
            from: offset * 10 - 10,
            size: 10,
            query: {
                query_string: {
                    query: query,
                    fields: ["inurl^100","intitle^50","intext^5"],
                    default_operator: "AND",
                    fuzziness: "AUTO",
                    //analyzer: "russian"
                }
            },
            highlight: {
                order: "score",
                fields: {
                    "*": {
                        pre_tags: ["_b_"],
                        post_tags: ["_/b_"],
                        fragment_size: 250,
                        number_of_fragments: 3
                    }
                }
            }
        }
    } )
    .then( function(res) {
        var found = res.hits.total
        pages = []
        for( var i = 0; i < res.hits.hits.length; i++ )
        {
            var id = res.hits.hits[i]._id
            var relevant = res.hits.hits[i]._score
            var timestamp = res.hits.hits[i]._source.date
            var url = res.hits.hits[i]._source.inurl
            var filetype = res.hits.hits[i]._source.filetype
            var href = url
            var matches = []
            for( item in res.hits.hits[i].highlight )
            {
                if(item == 'inurl')
                    url = res.hits.hits[i].highlight[item][0]
                else if(item == 'intext')
                    matches.push( res.hits.hits[i].highlight[item] )
            }
            pages.push( {
                cache: "/" + index + "/cache?id=" + id,
                href: href,
                url: url.replace(/_b_/g, '<b>').replace(/_\/b_/g, '</b>'),
                filetype: filetype,
                relevant: relevant,
                timestamp: timestamp,
                matches: matches.join(" ... ").replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/_b_/g, '<b>').replace(/_\/b_/g, '</b>')
            } )
        }
        fs.readFile( "templates/search.html", "utf8", function(e,data) {
            var html = ejs.render(data, {
                found: found,
                query: query,
                pages: pages,
                offset: offset
            })
            response.writeHead(200, {"Content-Type": "text/html; charset=utf-8"})
            response.end(html)
        } )
    } )
}


exports.start = start
exports.search = search
exports.autocomplete = autocomplete
exports.cache = cache