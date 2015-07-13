var Shred = require("./shred");
var shred = new Shred();
var listId;

function getData(url, acceptHeader, cb, attempts) {
  if(!cb){
    cb = acceptHeader;
    acceptHeader = "application/json";
  }
  shred.get({
    url: window.location.protocol + "//" + window.location.host + url,
    headers: {
      Accept: acceptHeader
    },
    on: {
      // You can use response codes as events
      200: function(response) {
        // Shred will automatically JSON-decode response bodies that have a
        // JSON Content-Type
        if(response._raw.xhr.getResponseHeader("Status") == "304 Not Modified"){
          console.log("Got a 304 request for " + url);
          cb(response.content.data, 304);
        } else {
          console.log("Got a non-304 request for " + url);
          cb(response.content.data, 200);
        }
      },
      // Any other response means something's wrong
      response: function(response) {
        if(!attempts) {
          attempts = 1;
        }
        if(attempts < 5){
          console.log("Oh no! Trying again for attempt " + attempts);
          setTimeout(function(){
            getData(url, acceptHeader, cb, attempts + 1);
          }, 3000);
        } else {
          console.log("Attempted too many times, stopping");
        }
      }
    }
  });
}

function postData(url, data, cb, attempts) {
  shred.post({
    url: window.location.protocol + "//" + window.location.host + url,
    content: data,
    headers: {
      "Content-Type": "application/json"
    },
    on: {
      201: function(response) {
        if(cb){
          cb(response.content.data);
        }
      },
      200: function(response) {
        if(cb){
          cb(response.content.data);
        }
      },
      response: function(response){
        if(!attempts) {
          attempts = 1;
        }
        if(attempts < 3){
          console.log("Oh no! Trying post again for attempt " + attempts);
          setTimeout(function(){
            postData(url, data, cb, attempts + 1);
          }, 1000);
        } else {
          console.log("Attempted too many times, stopping");
        }
      }
    }
  });
}

function choseName(winner, loser){
	postData("/chose/" + listId, {winner: winner, loser: loser}, displayChoice);
}

choseTie = function(){
	postData("/chose_tie/" + listId, {name1: $("#name1").html(), name2: $("#name2").html()}, displayChoice);
}

clickedOne = function(){
	choseName($("#name1").html(), $("#name2").html());	
}

clickedTwo = function(){
	choseName($("#name2").html(), $("#name1").html());	
}

displayChoice = function(data){
	$("#list-title").html(data.list_title);
	$("#name1").html(data.name1);
	$("#name2").html(data.name2);
	$("#list-selection").hide();
	$("#results").hide();
	$("#name-choice").show();
}

startRanking = function(){
	listId = $("#existing-lists").val();
	getData("/display_choice/" + listId, displayChoice);
}

duplicate = function(){
	getData("/duplicate_list/" + $("#duplicate-list").val(), function(data){
		listId = data.id;
		getData("/display_choice/" + listId, displayChoice);
	});
}

displayResults = function(){
	getData("/results/" + listId, function(data){
		$("#results-html").html(data.html);
		$("#list-selection").hide();
		$("#name-choice").hide();
		$("#results").show();
	});
}

backToChoices = function(){
	$("#list-selection").hide();
	$("#results").hide();
	$("#name-choice").show();
}

backToListSelect = function(){
	$("#results").hide();
	$("#name-choice").hide();
	$("#list-selection").show();
}
