// Published men's hole pars and stroke indexes; verify against current physical scorecard.
const make=(par,stroke)=>par.map((p,i)=>({number:i+1,par:p,stroke:stroke[i]}));
export const courseHoles={
 indian:make([4,5,4,3,4,4,4,3,4,4,3,5,3,4,4,4,4,5],[4,18,10,14,2,12,16,6,8,3,17,11,9,1,7,5,15,13]),
 qualchan:make([4,4,5,3,5,4,3,4,4,4,3,4,4,3,4,5,4,5],[15,1,7,9,3,13,17,5,11,8,4,2,14,18,16,12,10,6]),
 downriver:make([5,3,4,4,4,3,5,3,4,4,4,3,5,5,4,3,4,4],[15,11,7,3,1,13,5,9,17,4,6,2,10,12,8,14,18,16]),
 esmeralda:make([4,3,5,4,4,4,4,3,4,4,4,3,4,4,5,4,3,4],[7,13,17,9,11,5,1,3,15,14,6,10,18,16,12,2,8,4])
};
export const scorecardSources={indian:'https://zommagolf.com/courses/wa/indian-canyon-golf-course',qualchan:'https://18birdies.com/golf-courses/club/b0dba8c0-86ac-11e4-8c28-020000005b00/the-creek-at-qualchan',downriver:'https://18birdies.com/golf-courses/club/b0dc6c10-86ac-11e4-8c28-020000005b00/downriver-golf-course',esmeralda:'https://zommagolf.com/courses/wa/esmeralda-golf-course'};
