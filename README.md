## Homebase Schedule App ##
Open your terminal an navigate to the app.rb file on the server directory
<p> cd schedule-app <br>
cd server<br>
ruby app.rb </p>

On another terminal navigate to the root directory
<p> cd schedule-app <br>
npm install<br>
npm start </p>

## OpenAI feature ##
<p> Since we're a startup and want to have a balance between our employees. <br>
We decided to bring a little of AI into our weekly planner, and decided to ask OpenAI model gpt-3.5 to help in this planning. </p>

<p>Open your terminal and do:<br>
git pull origin openai-feat<br>
</p>

<p>Navigate to:<br>
cd schedule-app/server<br>
export OPENAI_ACCESS_TOKEN="your_openai_api_key"<br>
ruby app.rb<br></p>

<p>Now open another terminal and:<br>
cd schedule-app<br>
npm install<br>
npm start</p>

And you should be ready to see the generated weekly plan for next week.
