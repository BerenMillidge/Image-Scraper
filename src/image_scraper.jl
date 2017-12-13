# okay, let's test out our image scraper, to see if this works at all - probably not

# needs selenium installed, and chrome driver, if you can, so idk

using PyCall
using WebDriver
using Requests
using JSON
using FileIO

#setup and init our driver
#chrome_path = "/home/beren/work/julia/misc/chromedriver"
#driver = init_chrome(chrome_path)

#searchtext = "cats"
#num_requested = 10
#num_scrolls = num_requested/400+1 #400 will be opened in the browser each time
#
#url = "https://www.google.com/search?q=" * searchtext * "&source=lnms&tbm=isch"
#get(driver, url)

#extensions = ("jpg", "jpeg", "png", "gif")

#img_count = 0
#downloaded_img_count = 0

#for i in 1:num_scrolls
#	for j in 1:10
#		execute_script(driver, "window.scrollBy(0, 100000000)")
#		sleep(0.2)
#	end

#	el =find_element_by_xpath(driver, "//input[@value='Show more results']")
#	click(el)
#	sleep(0.4)
#end


function scrollThroughPage(driver::WebDriver.Driver)
	#set up our constants here, not too bad, but a slight improvement
	const scrollScript = "window.scrollBy(0, 1000000)"
	const waitTime= 0.2
	const scrolls = 5
	for i in 1:scrolls
		execute_script(driver, scrollScript)
		sleep(waitTime)
	end
end

function clickThroughPage(driver::WebDriver.Driver)
	const nextButtonSelector = "//input[@value='Show more results']"
	const waitTime= 0.2
	click(find_element_by_xpath(driver, nextButtonSelector))
	sleep(waitTime)
end


#imgs = find_elements_by_xpath(driver, "//div[contains(@class, 'rg_meta')]")#

#img = imgs[1]
#print(img)
#println("")
#print(typeof(img))
#println("")
#innerhtml = JSON.parse(get_attribute(img, "innerHTML"))
#img_url = innerhtml["ou"]
#img_type = innerhtml["ity"]

#println("")
#println(img_url)
#println(img_type)

#not sureif we need to specify it being a tuple here. Honestly, who even knows? argh
#we should probably do dependency injection so it's not too bad, but who knows right?
function parseImageElement(img::WebDriver.WebElement, extensions::Tuple)
	innerhtml = JSON.parse(get_attribute(img, "innerHTML"))
	img_url = innerhtml["ou"]
	img_type = innerhtml["ity"]

	#we do our default type replacing here
	if !(img_type in extensions)
		img_type = "jpg"
	end
	return img_url, img_type
end

function requestAndSaveImage(url::AbstractString, fname::AbstractString, stream::Bool=false)
	if stream == true
		try
			stream = Requests.get_streaming(url)
			open(fname, "w") do file
				while !eof(stream)
					write(file, readavailable(stream))
				end
			end
		catch Exception e
			println("Image stream failed: " * e)
		end
	end

	if stream ==false
		try
			res = Requests.get(url)
			Requests.save(res, fname)
		catch Exception e
			println("Image download failed: " *e)
		end
	end
end

#okay, now time for the mega function, so we can se if this even works. If it does then hooray!!! we'll have done really well, and written ourselves an images scraper. Not bad for an evenings work! although it'sgot nothing to do with the actual phd... argh!

function scrape_images(searchTerm::AbstractString, num_images::Integer, basepath::AbstractString=searchTerm, streaming::Bool=false, parallel::Bool = false, extensions::Tuple=("jpg", "jpeg", "png", "gif"), verbose::Bool = true)
	#that's a seriously long function lol, but could be useful!

	const url = "https://www.google.co.in/search?q="*searchTerm*"&source=lnms&tbm=isch"

	#setup our images per page
	const images_per_page = 400
	
	number_of_scrolls = num_images/images_per_page +1

	#at some point we'll allow search engine customization, but not yet as I can't be bothered

	#setup driver
	const driver_path = "/home/beren/work/julia/misc/chromedriver" # this will need to be set up something properly and not put ongithub as an actual thing, hopefully
	driver = init_chrome(driver_path)
	#also should allow driver customizatoin at some point, but can't be bothered - could perhaps pare this into a separate function also for  ease
	if verbose==true
		println("Driver initialized")
	end

	#get the search term
	get(driver, url)

	if verbose==true
		println("Searching for " * searchTerm)
	

	#if all of this works, we make the dirs for our thing
	if !isdir(basepath)
		mkdir(basepath)
	end

	#now we scroll sufficiently
	img_counter::Integer = 0
	for i in 1:number_of_scrolls
		scrollThroughPage(driver) # scroll through page to load all images
		images = find_elements_by_xpath(driver,"//div[contains(@class, 'rg_meta')]") # get image urls
		println("Total Images found on this page: " * string(length(images)))
		for img in images

			img_url, img_type = parseImageElement(img, extensions) # parse our image
			fname = basepath*searchTerm * "_"*string(img_counter)*"."*img_type # create filename for saving
			requestAndSaveImage(img_url, fname, streaming)
			img_counter +=1
			
			#and we check our loop functionality
			if img_counter >= num_images
				if verbose==true
					println(string(num_images) *" images found. Image scraper exiting")
				end
				return
			end
		end
	end
end
	#okay, that's largely it to be honest idk really

const basepath ="/home/beren/work/julia/scrape_tests/"
const num_pics = 20
const search="cats"
scrape_images(search, num_pics, basepath)
			
		
	



#we now get our image
#println("")
#response = get(img_url)
#println(response)
#println(typeof(response))

#img = response.data
#fname=searchtext *"_test_julia" * "."*img_type
#Requests.save(response, fname)
